#!/usr/bin/python3
"""notifyd: convierte eventos del sistema en notificaciones de swaync.

Vigila batería, Bluetooth, USB, red, descargas, actualizaciones, reinicio pendiente,
disco, temperatura y servicios caídos. Corre como servicio de usuario (notifyd.service).

    notifyd.py          demonio
    notifyd.py --demo   manda un ejemplo de cada aviso, por los mismos caminos que el demonio
"""
import json
import os
import shlex
import shutil
import subprocess
import sys
from collections import deque
from pathlib import Path

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

ICONS = Path.home() / ".config/swaync/icons"
STATE_FILE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "notifyd.json"

BATTERY_LEVELS = (5, 10, 20)     # % en los que avisa al descargarse
DISK_LEVELS = (90, 95)           # % de uso
TEMP_LIMIT = 98                  # °C, sostenidos TEMP_SAMPLES lecturas seguidas
TEMP_SAMPLES = 3
TEMP_COOLDOWN = 15 * 60          # s entre avisos de temperatura

TICK = 20                        # s entre lecturas de temperatura
SLOW_CHECK = 10 * 60             # s entre revisiones de disco, kernel y servicios
UPDATE_CHECK = 6 * 3600          # s entre búsquedas de actualizaciones
UPDATE_DELAY = 180               # s tras arrancar, con la red ya levantada
BT_SETTLE = 2                    # s para que el dispositivo publique su batería
NET_DEBOUNCE_UP = 2              # s antes de avisar de conexión
NET_DEBOUNCE_DOWN = 10           # s antes de avisar de corte: un cambio de red o suspender no cuenta
DEMO_LINGER = 7                  # s que se ven los avisos de --demo antes de retirarlos

UPOWER_STATE_CHARGING, UPOWER_STATE_DISCHARGING, UPOWER_STATE_FULL = 1, 2, 4
PARTIAL_DOWNLOAD = (".part", ".crdownload", ".download")
BT_ICONS = (("audio", "headphones"), ("input-mouse", "mouse"), ("input-keyboard", "keyboard"),
            ("input-gaming", "game"))


# ── Lógica pura (cubierta por tests/test_notifyd.py) ─────────────────────────
def battery_level(percent):
    """El umbral más bajo alcanzado, o None por encima de todos."""
    return next((level for level in BATTERY_LEVELS if percent <= level), None)


def should_alert_battery(level, last_level):
    """Solo avisa al cruzar un umbral nuevo hacia abajo."""
    return level is not None and (last_level is None or level < last_level)


def disk_level(percent):
    """El umbral más alto superado, o None."""
    return next((level for level in reversed(DISK_LEVELS) if percent >= level), None)


def format_duration(seconds):
    if seconds <= 0:
        return ""
    hours, minutes = seconds // 3600, seconds % 3600 // 60
    return f"{hours} h {minutes} min" if hours else f"{max(minutes, 1)} min"


def format_size(num):
    size = float(num)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024:
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}".replace(".", ",")
        size /= 1024
    return f"{size:.1f} TB".replace(".", ",")


def parse_updates(text):
    """Nombres de paquete en la salida de checkupdates o yay -Qua."""
    return [line.split()[0] for line in text.splitlines() if line.strip()]


def updates_body(pacman, aur):
    names = (pacman + aur)[:5]
    extra = len(pacman) + len(aur) - len(names)
    return ", ".join(names) + (f" y {extra} más" if extra else "")


def finished_download(old_name, new_name):
    """Los navegadores descargan en foo.part y al acabar lo renombran a foo."""
    return old_name.endswith(PARTIAL_DOWNLOAD) and not new_name.endswith(PARTIAL_DOWNLOAD)


def bluetooth_icon(device_icon):
    return next((icon for prefix, icon in BT_ICONS if (device_icon or "").startswith(prefix)), "bluetooth")


def parse_failed_units(text):
    """Primera columna de systemctl --failed --plain --no-legend."""
    return [line.split()[0] for line in text.splitlines() if line.strip()]


def new_items(current, known):
    return sorted(set(current) - set(known))


# ── Utilidades ───────────────────────────────────────────────────────────────
class State:
    """Lo avisado se recuerda entre reinicios para no repetirlo."""

    def __init__(self, path=STATE_FILE):
        self.path = path
        try:
            self.data = json.loads(path.read_text())
        except (OSError, ValueError):
            self.data = {}

    def get(self, key, default=None):
        return self.data.get(key, default)

    def set(self, key, value):
        self.data[key] = value
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.data))
        tmp.replace(self.path)


def run_async(argv, callback):
    """Ejecuta argv sin bloquear el bucle; callback(código, stdout)."""
    try:
        proc = Gio.Subprocess.new(argv, Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE)
    except GLib.Error as err:
        print(f"no se pudo ejecutar {argv[0]}: {err.message}", file=sys.stderr)
        callback(127, "")
        return

    def done(p, result):
        try:
            _, out, _ = p.communicate_utf8_finish(result)
            callback(p.get_exit_status(), out or "")
        except GLib.Error:
            callback(1, "")
    proc.communicate_utf8_async(None, None, done)


def spawn(*argv):
    """Lanza una app sin esperar, desligada del servicio."""
    subprocess.Popen(argv, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def terminal(command, title):
    spawn("kitty", "--title", title, "bash", "-c", f'{command}; echo; read -r -p "Pulsa Intro para cerrar" _')


# ── Notificaciones ───────────────────────────────────────────────────────────
class Notifier:
    LOW, NORMAL, CRITICAL = 0, 1, 2

    def __init__(self, bus):
        self.bus = bus
        self.actions = {}    # id de notificación → {acción: callback}
        self.sent = deque(maxlen=32)
        bus.signal_subscribe(None, "org.freedesktop.Notifications", "ActionInvoked",
                             "/org/freedesktop/Notifications", None, Gio.DBusSignalFlags.NONE, self._invoked)
        bus.signal_subscribe(None, "org.freedesktop.Notifications", "NotificationClosed",
                             "/org/freedesktop/Notifications", None, Gio.DBusSignalFlags.NONE, self._closed)

    def send(self, app, summary, body="", icon="bell", urgency=NORMAL, key=None, actions=None,
             value=None, transient=False):
        """actions: [(id, etiqueta, callback), ...]. key: sustituye al aviso anterior con la misma clave."""
        hints = {"urgency": GLib.Variant("y", urgency),
                 "image-path": GLib.Variant("s", f"file://{ICONS / icon}.png")}
        if key:
            hints["x-canonical-private-synchronous"] = GLib.Variant("s", key)
        if value is not None:
            hints["value"] = GLib.Variant("i", value)
        if transient:
            hints["transient"] = GLib.Variant("b", True)
        labels = [part for action, label, _ in actions or [] for part in (action, label)]

        def done(bus, result):
            try:
                notification_id = bus.call_finish(result)[0]
            except GLib.Error as err:
                print(f"no se pudo notificar: {err.message}", file=sys.stderr)
                return
            self.sent.append(notification_id)
            if actions:
                self.actions[notification_id] = {action: cb for action, _, cb in actions}

        self.bus.call("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                      "org.freedesktop.Notifications", "Notify",
                      GLib.Variant("(susssasa{sv}i)", (app, 0, "", summary, body, labels, hints, -1)),
                      GLib.VariantType("(u)"), Gio.DBusCallFlags.NONE, -1, None, done)

    def close(self, notification_id):
        self.bus.call("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                      "org.freedesktop.Notifications", "CloseNotification", GLib.Variant("(u)", (notification_id,)),
                      None, Gio.DBusCallFlags.NONE, -1, None, None)

    def _invoked(self, _bus, _sender, _path, _iface, _signal, params):
        notification_id, action = params.unpack()
        callback = self.actions.pop(notification_id, {}).get(action)
        if callback:
            callback()

    def _closed(self, _bus, _sender, _path, _iface, _signal, params):
        self.actions.pop(params.unpack()[0], None)


# ── Mensajes ─────────────────────────────────────────────────────────────────
class Messages:
    """Texto, icono y botones de cada aviso. Los módulos solo detectan; --demo llama a esto mismo."""

    def __init__(self, notifier):
        self.send = notifier.send

    def battery_low(self, level, percent, seconds):
        critical = level <= BATTERY_LEVELS[0]
        left = format_duration(seconds)
        self.send("Batería", f"Batería al {percent} %", f"Quedan unos {left}" if left else "Conecta el cargador",
                  icon="battery-critical" if critical else "battery-low", key="notifyd-battery",
                  urgency=Notifier.CRITICAL if critical else Notifier.NORMAL, value=percent)

    def charger_unplugged(self, percent, seconds):
        left = format_duration(seconds)
        self.send("Batería", "Cargador desconectado", f"{percent} %" + (f" · quedan {left}" if left else ""),
                  icon="plug-off", urgency=Notifier.LOW, key="notifyd-battery", value=percent, transient=True)

    def charging(self, percent, seconds):
        left = format_duration(seconds)
        self.send("Batería", "Cargando", f"{percent} %" + (f" · lleno en {left}" if left else ""),
                  icon="battery-charging", urgency=Notifier.LOW, key="notifyd-battery", value=percent, transient=True)

    def battery_full(self):
        self.send("Batería", "Batería cargada", "Ya puedes desconectar el cargador", icon="battery-full",
                  urgency=Notifier.LOW, key="notifyd-battery", transient=True)

    def bt_connected(self, name, kind, battery):
        self.send("Bluetooth", name, "Conectado" + (f" · batería {battery} %" if battery is not None else ""),
                  icon=bluetooth_icon(kind), urgency=Notifier.LOW, key=f"notifyd-bt-{name}", transient=True)

    def bt_disconnected(self, name):
        self.send("Bluetooth", name, "Desconectado", icon="bluetooth-off", urgency=Notifier.LOW,
                  key=f"notifyd-bt-{name}", transient=True)

    def usb_inserted(self, name, size, open_cb, eject_cb):
        self.send("Almacenamiento", name, f"Unidad USB · {format_size(size)}", icon="usb", key=f"notifyd-usb-{name}",
                  actions=[("default", "Abrir", open_cb), ("open", "Abrir", open_cb), ("eject", "Expulsar", eject_cb)])

    def usb_removed(self, name):
        self.send("Almacenamiento", name, "Retirada", icon="usb", urgency=Notifier.LOW, key=f"notifyd-usb-{name}",
                  transient=True)

    def usb_ejected(self, name):
        self.send("Almacenamiento", "Ya puedes retirarla", name, icon="usb", urgency=Notifier.LOW,
                  key=f"notifyd-usb-{name}", transient=True)

    def usb_error(self, name, detail):
        self.send("Almacenamiento", f"Problema con {name}", detail, icon="service", key=f"notifyd-usb-{name}")

    def online(self, name, kind):
        self.send("Red", "Conectado", name, icon="wifi" if "wireless" in kind else "ethernet", urgency=Notifier.LOW,
                  key="notifyd-net", transient=True)

    def offline(self):
        self.send("Red", "Sin conexión", "Se ha perdido la red", icon="wifi-off", key="notifyd-net")

    def download_finished(self, path, size):
        open_file = lambda: spawn("xdg-open", str(path))
        self.send("Descargas", "Descarga completada", f"{path.name} · {format_size(size)}", icon="download", actions=[
            ("default", "Abrir", open_file), ("open", "Abrir", open_file),
            ("folder", "Ver carpeta", lambda: spawn("xdg-open", str(path.parent))),
        ])

    def updates_available(self, pacman, aur):
        total = len(pacman) + len(aur)
        title = "1 actualización" if total == 1 else f"{total} actualizaciones"
        self.send("Actualizaciones", title, updates_body(pacman, aur), icon="update", key="notifyd-updates",
                  actions=[("update", "Actualizar", lambda: terminal("yay", "Actualizar el sistema"))])

    def hot(self, celsius):
        self.send("Sistema", f"CPU a {celsius} °C", "Revisa la ventilación o cierra lo que esté cargando el procesador",
                  icon="temperature", key="notifyd-temp")

    def disk_full(self, mount, percent, free):
        critical = percent >= DISK_LEVELS[-1]
        self.send("Sistema", f"Disco al {percent} %", f"{mount} · quedan {format_size(free)}", icon="disk",
                  urgency=Notifier.CRITICAL if critical else Notifier.NORMAL, key=f"notifyd-disk-{mount}", value=percent,
                  actions=[("open", "Abrir", lambda: spawn("xdg-open", mount))])

    def reboot_needed(self, release):
        self.send("Sistema", "Reinicio pendiente", f"El kernel {release} ya no está instalado: algunos módulos pueden fallar",
                  icon="restart", key="notifyd-kernel")

    def service_failed(self, unit, scope):
        scope_flag = "--user " if scope == "user" else ""
        command = f"journalctl {scope_flag}-u {shlex.quote(unit)} -n 50 --no-pager"
        self.send("Sistema", "Servicio caído", unit, icon="service", key=f"notifyd-unit-{unit}",
                  actions=[("log", "Ver registro", lambda: terminal(command, unit))])


# ── Módulos ──────────────────────────────────────────────────────────────────
class Battery:
    def __init__(self, say):
        self.say = say
        self.last_level = None
        self.upower = Gio.DBusProxy.new_for_bus_sync(
            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, None, "org.freedesktop.UPower",
            "/org/freedesktop/UPower", "org.freedesktop.UPower", None)
        self.device = Gio.DBusProxy.new_for_bus_sync(
            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, None, "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/DisplayDevice", "org.freedesktop.UPower.Device", None)
        self.was_on_battery = self._prop(self.upower, "OnBattery")
        self.was_full = self._prop(self.device, "State") == UPOWER_STATE_FULL
        self.upower.connect("g-properties-changed", self._power_changed)
        self.device.connect("g-properties-changed", self._device_changed)
        self._device_changed()

    @staticmethod
    def _prop(proxy, name):
        value = proxy.get_cached_property(name)
        return value.unpack() if value is not None else None

    def _power_changed(self, *_):
        on_battery = self._prop(self.upower, "OnBattery")
        if on_battery is None or on_battery == self.was_on_battery:
            return
        self.was_on_battery = on_battery
        percent = round(self._prop(self.device, "Percentage") or 0)
        if on_battery:
            self.say.charger_unplugged(percent, self._prop(self.device, "TimeToEmpty") or 0)
        else:
            self.say.charging(percent, self._prop(self.device, "TimeToFull") or 0)

    def _device_changed(self, *_):
        percent = self._prop(self.device, "Percentage")
        state = self._prop(self.device, "State")
        if percent is None or state is None:
            return
        full = state == UPOWER_STATE_FULL
        if full and not self.was_full:
            self.say.battery_full()
        self.was_full = full

        if state != UPOWER_STATE_DISCHARGING:
            self.last_level = None
            return
        level = battery_level(percent)
        if should_alert_battery(level, self.last_level):
            self.last_level = level
            self.say.battery_low(level, round(percent), self._prop(self.device, "TimeToEmpty") or 0)


class Bluetooth:
    def __init__(self, say):
        self.say = say
        self.manager = Gio.DBusObjectManagerClient.new_for_bus_sync(
            Gio.BusType.SYSTEM, Gio.DBusObjectManagerClientFlags.DO_NOT_AUTO_START,
            "org.bluez", "/", None, None, None)
        self.manager.connect("interface-proxy-properties-changed", self._changed)

    def _changed(self, _manager, _object, iface, changed, _invalidated):
        if iface.get_interface_name() != "org.bluez.Device1":
            return
        connected = changed.unpack().get("Connected")
        if connected is None:
            return
        alias = iface.get_cached_property("Alias")
        icon = iface.get_cached_property("Icon")
        name = alias.unpack() if alias else "Dispositivo"
        if connected:
            GLib.timeout_add_seconds(BT_SETTLE, self._announce, iface.get_object_path(), name,
                                     icon.unpack() if icon else "")
        else:
            self.say.bt_disconnected(name)

    def _announce(self, path, name, kind):
        battery = self.manager.get_interface(path, "org.bluez.Battery1")
        level = battery.get_cached_property("Percentage") if battery else None
        self.say.bt_connected(name, kind, level.unpack() if level else None)
        return GLib.SOURCE_REMOVE


class Storage:
    FS = "org.freedesktop.UDisks2.Filesystem"
    BLOCK = "org.freedesktop.UDisks2.Block"
    DRIVE = "org.freedesktop.UDisks2.Drive"

    def __init__(self, say):
        self.say = say
        self.names = {}      # ruta D-Bus → nombre, para anunciar la retirada
        self.manager = Gio.DBusObjectManagerClient.new_for_bus_sync(
            Gio.BusType.SYSTEM, Gio.DBusObjectManagerClientFlags.NONE,
            "org.freedesktop.UDisks2", "/org/freedesktop/UDisks2", None, None, None)
        # Un objeto nuevo solo emite object-added; interface-added es para objetos que ya existían
        self.manager.connect("object-added", self._object_added)
        self.manager.connect("interface-added", self._interface_added)
        self.manager.connect("object-removed", self._object_removed)
        self.manager.connect("interface-removed", self._interface_removed)

    def _object_added(self, _manager, obj):
        fs = obj.get_interface(self.FS)
        if fs:
            self._announce(obj, fs)

    def _interface_added(self, _manager, obj, iface):
        if iface.get_interface_name() == self.FS:
            self._announce(obj, iface)

    def _object_removed(self, _manager, obj):
        name = self.names.pop(obj.get_object_path(), None)
        if name:
            self.say.usb_removed(name)

    def _interface_removed(self, manager, obj, iface):
        if iface.get_interface_name() == self.FS:
            self._object_removed(manager, obj)

    def _announce(self, obj, fs):
        path = obj.get_object_path()
        block = obj.get_interface(self.BLOCK)
        if path in self.names or not block:
            return
        drive_path = block.get_cached_property("Drive").unpack()
        drive = self.manager.get_interface(drive_path, self.DRIVE) if drive_path != "/" else None
        if not drive or drive.get_cached_property("ConnectionBus").unpack() not in ("usb", "sdio"):
            return
        vendor = drive.get_cached_property("Vendor").unpack().strip()
        model = drive.get_cached_property("Model").unpack().strip()
        name = block.get_cached_property("IdLabel").unpack() or f"{vendor} {model}".strip() or "Unidad USB"
        device = bytes(block.get_cached_property("PreferredDevice").unpack()).rstrip(b"\0").decode()
        self.names[path] = name
        self.say.usb_inserted(name, block.get_cached_property("Size").unpack(),
                              lambda: self._open(fs, name), lambda: self._eject(device, name))

    def _open(self, fs, name):
        mounts = fs.get_cached_property("MountPoints").unpack()
        if mounts:
            spawn("xdg-open", bytes(mounts[0]).rstrip(b"\0").decode())
            return

        def mounted(proxy, result):
            try:
                spawn("xdg-open", proxy.call_finish(result)[0])
            except GLib.Error as err:
                self.say.usb_error(name, err.message)
        fs.call("Mount", GLib.Variant("(a{sv})", ({},)), Gio.DBusCallFlags.NONE, -1, None, mounted)

    def _eject(self, device, name):
        def done(code, _out):
            if code == 0:
                self.say.usb_ejected(name)
            else:
                self.say.usb_error(name, "No se ha podido expulsar: sigue en uso")
        run_async(["sh", "-c", 'udisksctl unmount --no-user-interaction -b "$0" >/dev/null 2>&1;'
                   'udisksctl power-off --no-user-interaction -b "$0"', device], done)


class Network:
    NM = "org.freedesktop.NetworkManager"

    def __init__(self, say):
        self.say = say
        self.timer = 0
        self.proxy = Gio.DBusProxy.new_for_bus_sync(
            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.DO_NOT_AUTO_START, None, self.NM,
            "/org/freedesktop/NetworkManager", self.NM, None)
        self.last = self._current()
        self.proxy.connect("g-properties-changed", self._changed)

    def _current(self):
        """(nombre, tipo) de la conexión principal, o None sin red."""
        primary = self.proxy.get_cached_property("PrimaryConnection")
        path = primary.unpack() if primary else "/"
        if path == "/":
            return None
        active = Gio.DBusProxy.new_for_bus_sync(
            Gio.BusType.SYSTEM, Gio.DBusProxyFlags.DO_NOT_AUTO_START, None, self.NM, path,
            f"{self.NM}.Connection.Active", None)
        name, kind = active.get_cached_property("Id"), active.get_cached_property("Type")
        return (name.unpack(), kind.unpack()) if name and kind else None

    def _changed(self, _proxy, changed, _invalidated):
        if "PrimaryConnection" not in changed.unpack():
            return
        if self.timer:
            GLib.source_remove(self.timer)
        delay = NET_DEBOUNCE_UP if self._current() else NET_DEBOUNCE_DOWN
        self.timer = GLib.timeout_add_seconds(delay, self._settle)

    def _settle(self):
        self.timer = 0
        current = self._current()
        if current != self.last:
            self.last = current
            if current:
                self.say.online(*current)
            else:
                self.say.offline()
        return GLib.SOURCE_REMOVE


class Downloads:
    def __init__(self, say, folder=None):
        self.say = say
        folder = folder or GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOWNLOAD) or str(Path.home() / "Downloads")
        self.monitor = Gio.File.new_for_path(folder).monitor_directory(Gio.FileMonitorFlags.WATCH_MOVES, None)
        self.monitor.connect("changed", self._changed)

    def _changed(self, _monitor, source, other, event):
        if event == Gio.FileMonitorEvent.RENAMED and other and finished_download(source.get_basename(), other.get_basename()):
            path = Path(other.get_path())
            try:
                self.say.download_finished(path, path.stat().st_size)
            except OSError:
                pass


class Updates:
    def __init__(self, say, state):
        self.say = say
        self.state = state
        GLib.timeout_add_seconds(UPDATE_DELAY, self._first_check)
        GLib.timeout_add_seconds(UPDATE_CHECK, self.check)

    def _first_check(self):
        self.check()
        return GLib.SOURCE_REMOVE

    def check(self):
        def after_pacman(code, out):
            # checkupdates: 0 hay, 2 no hay, otro error (sin red, base de datos bloqueada)
            if code in (0, 2):
                run_async(["yay", "-Qua"], lambda _code, aur: self.report(parse_updates(out), parse_updates(aur)))
        run_async(["checkupdates"], after_pacman)
        return GLib.SOURCE_CONTINUE

    def report(self, pacman, aur):
        current = pacman + aur
        new = new_items(current, self.state.get("updates", []))
        self.state.set("updates", current)
        if new:
            self.say.updates_available(pacman, aur)


class Health:
    """Revisiones periódicas: temperatura, disco, kernel y servicios."""

    def __init__(self, say, state):
        self.say = say
        self.state = state
        self.hot_samples = 0
        self.cooldown_until = 0
        self.sensor = self._find_cpu_sensor()
        GLib.timeout_add_seconds(TICK, self.temperature)
        GLib.timeout_add_seconds(SLOW_CHECK, self.slow)
        GLib.timeout_add_seconds(60, self._first_slow)

    def _first_slow(self):
        self.slow()
        return GLib.SOURCE_REMOVE

    @staticmethod
    def _find_cpu_sensor():
        for hwmon in Path("/sys/class/hwmon").glob("hwmon*"):
            try:
                if (hwmon / "name").read_text().strip() in ("coretemp", "k10temp"):
                    return hwmon / "temp1_input"
            except OSError:
                continue
        return None

    def temperature(self):
        if not self.sensor:
            return GLib.SOURCE_REMOVE
        try:
            celsius = int(self.sensor.read_text()) // 1000
        except (OSError, ValueError):
            return GLib.SOURCE_CONTINUE
        self.hot_samples = self.hot_samples + 1 if celsius >= TEMP_LIMIT else 0
        now = GLib.get_monotonic_time() // 1_000_000
        if self.hot_samples >= TEMP_SAMPLES and now >= self.cooldown_until:
            self.cooldown_until = now + TEMP_COOLDOWN
            self.say.hot(celsius)
        return GLib.SOURCE_CONTINUE

    def slow(self):
        self.disk()
        self.kernel()
        self.services()
        return GLib.SOURCE_CONTINUE

    def disk(self):
        for mount in sorted({"/", str(Path.home())}):
            usage = shutil.disk_usage(mount)
            percent = usage.used * 100 // (usage.used + usage.free)    # igual que df
            level = disk_level(percent)
            key = f"disk:{mount}"
            if level != self.state.get(key):
                self.state.set(key, level)
                if level is not None:
                    self.say.disk_full(mount, percent, usage.free)

    def kernel(self):
        release = os.uname().release
        if not Path("/usr/lib/modules", release).exists() and self.state.get("stale_kernel") != release:
            self.state.set("stale_kernel", release)
            self.say.reboot_needed(release)

    def services(self):
        for scope, argv in (("user", ["systemctl", "--user"]), ("system", ["systemctl"])):
            run_async(argv + ["--failed", "--plain", "--no-legend"],
                      lambda _code, out, scope=scope: self.report_failed(scope, parse_failed_units(out)))

    def report_failed(self, scope, failed):
        key = f"failed:{scope}"
        new = new_items(failed, self.state.get(key, []))
        self.state.set(key, failed)
        for unit in new:
            self.say.service_failed(unit, scope)


# ── Arranque ─────────────────────────────────────────────────────────────────
def demo(notifier):
    """Un ejemplo de cada aviso, por los mismos métodos que los eventos reales.
    Al acabar los retira, para no dejar avisos falsos en el panel."""
    say = Messages(notifier)
    nothing = lambda: None
    sample = Path(GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DOWNLOAD) or "/tmp") / "informe-final.pdf"
    steps = [
        lambda: say.battery_low(20, 19, 4500),
        lambda: say.battery_low(5, 5, 600),
        lambda: say.charger_unplugged(72, 11000),
        lambda: say.charging(72, 2700),
        lambda: say.battery_full(),
        lambda: say.bt_connected("WH-1000XM4", "audio-headset", 80),
        lambda: say.bt_disconnected("WH-1000XM4"),
        lambda: say.usb_inserted("KINGSTON", 32_000_000_000, nothing, nothing),
        lambda: say.online("Casa_5G", "802-11-wireless"),
        lambda: say.offline(),
        lambda: say.download_finished(sample, 4_200_000),
        lambda: say.updates_available(["linux-zen", "mesa", "hyprland", "pipewire", "firefox", "bash"], ["zen-browser-bin"]),
        lambda: say.hot(99),
        lambda: say.disk_full("/", 91, 31_000_000_000),
        lambda: say.reboot_needed(os.uname().release),
        lambda: say.service_failed("panel-maestro.service", "user"),
    ]

    def step():
        steps.pop(0)()
        if steps:
            return GLib.SOURCE_CONTINUE
        GLib.timeout_add_seconds(DEMO_LINGER, finish)
        return GLib.SOURCE_REMOVE

    def finish():
        for notification_id in notifier.sent:
            notifier.close(notification_id)
        GLib.timeout_add(300, loop.quit)
        return GLib.SOURCE_REMOVE

    loop = GLib.MainLoop()
    GLib.timeout_add(int(os.environ.get("NOTIFYD_DEMO_MS", "700")), step)
    loop.run()


def main():
    notifier = Notifier(Gio.bus_get_sync(Gio.BusType.SESSION, None))
    if "--demo" in sys.argv:
        demo(notifier)
        return

    say = Messages(notifier)
    state = State()
    modules = []
    for build in (lambda: Battery(say), lambda: Bluetooth(say), lambda: Storage(say), lambda: Network(say),
                  lambda: Downloads(say), lambda: Updates(say, state), lambda: Health(say, state)):
        try:
            modules.append(build())     # sin Bluetooth o sin batería, el resto sigue funcionando
        except GLib.Error as err:
            print(f"módulo desactivado: {err.message}", file=sys.stderr)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
