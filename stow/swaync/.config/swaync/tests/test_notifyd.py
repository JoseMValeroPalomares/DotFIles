"""Tests de la lógica de notifyd. Ejecutar: python3 -m unittest discover -s ~/.config/swaync/tests"""
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "scripts"


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / filename)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


nd = load("notifyd", "notifyd.py")
gi = load("gen_icons", "gen-icons.py")


class Battery(unittest.TestCase):
    def test_levels(self):
        self.assertIsNone(nd.battery_level(21))
        self.assertEqual(nd.battery_level(20), 20)
        self.assertEqual(nd.battery_level(11), 20)
        self.assertEqual(nd.battery_level(10), 10)
        self.assertEqual(nd.battery_level(1), 5)

    def test_only_alerts_when_crossing_down(self):
        self.assertTrue(nd.should_alert_battery(20, None))
        self.assertFalse(nd.should_alert_battery(20, 20))
        self.assertTrue(nd.should_alert_battery(10, 20))
        self.assertFalse(nd.should_alert_battery(20, 10))
        self.assertFalse(nd.should_alert_battery(None, None))


class Format(unittest.TestCase):
    def test_duration(self):
        self.assertEqual(nd.format_duration(0), "")
        self.assertEqual(nd.format_duration(30), "1 min")
        self.assertEqual(nd.format_duration(600), "10 min")
        self.assertEqual(nd.format_duration(3660), "1 h 1 min")

    def test_size(self):
        self.assertEqual(nd.format_size(512), "512 B")
        self.assertEqual(nd.format_size(4_200_000), "4,0 MB")
        self.assertEqual(nd.format_size(32_000_000_000), "29,8 GB")
        self.assertEqual(nd.format_size(3 * 1024 ** 4), "3,0 TB")


class Updates(unittest.TestCase):
    def test_parse(self):
        text = "linux-zen 7.2.10-1 -> 7.2.11-1\nmesa 1:26 -> 1:27\n\n"
        self.assertEqual(nd.parse_updates(text), ["linux-zen", "mesa"])
        self.assertEqual(nd.parse_updates(""), [])

    def test_body_truncates(self):
        self.assertEqual(nd.updates_body(["a", "b"], ["c"]), "a, b, c")
        self.assertEqual(nd.updates_body(list("abcdefg"), []), "a, b, c, d, e y 2 más")


class Downloads(unittest.TestCase):
    def test_finished(self):
        self.assertTrue(nd.finished_download("foo.zip.part", "foo.zip"))
        self.assertTrue(nd.finished_download("foo.zip.crdownload", "foo.zip"))
        self.assertFalse(nd.finished_download("foo.zip", "bar.zip"))
        self.assertFalse(nd.finished_download("a.part", "b.part"))


class Misc(unittest.TestCase):
    def test_disk_levels(self):
        self.assertIsNone(nd.disk_level(89))
        self.assertEqual(nd.disk_level(90), 90)
        self.assertEqual(nd.disk_level(94), 90)
        self.assertEqual(nd.disk_level(99), 95)

    def test_bluetooth_icon(self):
        self.assertEqual(nd.bluetooth_icon("audio-headset"), "headphones")
        self.assertEqual(nd.bluetooth_icon("input-mouse"), "mouse")
        self.assertEqual(nd.bluetooth_icon("input-gaming"), "game")
        self.assertEqual(nd.bluetooth_icon(""), "bluetooth")
        self.assertEqual(nd.bluetooth_icon(None), "bluetooth")

    def test_failed_units(self):
        out = "foo.service loaded failed failed Foo\nbar.socket loaded failed failed Bar\n"
        self.assertEqual(nd.parse_failed_units(out), ["foo.service", "bar.socket"])
        self.assertEqual(nd.new_items(["a", "b"], ["a"]), ["b"])
        self.assertEqual(nd.new_items(["a"], ["a", "b"]), [])

    def test_state_survives_restart(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "deep/state.json"
            nd.State(path).set("updates", ["linux"])
            self.assertEqual(nd.State(path).get("updates"), ["linux"])
            path.write_text("no es json")
            self.assertIsNone(nd.State(path).get("updates"))


class Fake:
    """Sustituye a proxies y objetos de D-Bus."""

    def __init__(self, path="/", name="", props=None, ifaces=None):
        self.path, self.name, self.props, self.ifaces = path, name, props or {}, ifaces or {}

    def get_object_path(self):
        return self.path

    def get_interface_name(self):
        return self.name

    def get_interface(self, *args):
        return self.ifaces.get(args[-1])

    def get_cached_property(self, name):
        value = self.props.get(name)
        return Fake(props={"v": value}) if value is not None else None

    def unpack(self):
        return self.props["v"]


class Recorder:
    def __init__(self):
        self.calls = []

    def __getattr__(self, name):
        return lambda *args: self.calls.append((name, *args))


class StorageEvents(unittest.TestCase):
    def setUp(self):
        self.say = Recorder()
        self.storage = nd.Storage.__new__(nd.Storage)
        self.storage.say, self.storage.names = self.say, {}
        props = {"ConnectionBus": "usb", "Vendor": "Kingston ", "Model": "DataTraveler "}
        self.storage.manager = Fake(ifaces={nd.Storage.DRIVE: Fake(props=props)})

    def usb_object(self, label="KINGSTON", drive="/drives/usb"):
        block = Fake(props={"Drive": drive, "IdLabel": label, "Size": 1024,
                            "PreferredDevice": list(b"/dev/sdb1\0")})
        fs = Fake(name=nd.Storage.FS)
        return Fake("/block/sdb1", ifaces={nd.Storage.BLOCK: block, nd.Storage.FS: fs}), fs

    def test_new_object_is_announced_once(self):
        obj, fs = self.usb_object()
        self.storage._object_added(None, obj)
        self.storage._interface_added(None, obj, fs)    # no debe duplicar el aviso
        self.assertEqual([c[:3] for c in self.say.calls], [("usb_inserted", "KINGSTON", 1024)])

    def test_filesystem_added_later_is_announced(self):
        obj, fs = self.usb_object()
        self.storage._interface_added(None, obj, fs)
        self.assertEqual(self.say.calls[0][0], "usb_inserted")

    def test_internal_disk_is_ignored(self):
        self.storage.manager = Fake(ifaces={nd.Storage.DRIVE: Fake(props={"ConnectionBus": ""})})
        obj, _ = self.usb_object()
        self.storage._object_added(None, obj)
        self.assertEqual(self.say.calls, [])

    def test_loop_device_without_drive_is_ignored(self):
        obj, _ = self.usb_object(drive="/")
        self.storage._object_added(None, obj)
        self.assertEqual(self.say.calls, [])

    def test_unlabelled_uses_vendor_and_model(self):
        obj, _ = self.usb_object(label="")
        self.storage._object_added(None, obj)
        self.assertEqual(self.say.calls[0][1], "Kingston DataTraveler")

    def test_removal(self):
        obj, _ = self.usb_object()
        self.storage._object_added(None, obj)
        self.storage._object_removed(None, obj)
        self.assertEqual(self.say.calls[-1], ("usb_removed", "KINGSTON"))
        self.storage._object_removed(None, obj)         # desconocido: sin aviso
        self.assertEqual(len(self.say.calls), 2)


class NetworkEvents(unittest.TestCase):
    def setUp(self):
        self.say = Recorder()
        self.net = nd.Network.__new__(nd.Network)
        self.net.say, self.net.timer, self.net.last = self.say, 0, ("Casa", "802-11-wireless")

    def settle(self, current):
        self.net._current = lambda: current
        self.net._settle()

    def test_same_connection_is_silent(self):
        self.settle(("Casa", "802-11-wireless"))
        self.assertEqual(self.say.calls, [])

    def test_blip_shorter_than_debounce_is_silent(self):
        self.net._current = lambda: ("Casa", "802-11-wireless")     # volvió antes de asentarse
        self.net._settle()
        self.assertEqual(self.say.calls, [])

    def test_loss_and_recovery(self):
        self.settle(None)
        self.settle(("Casa", "802-11-wireless"))
        self.assertEqual([c[0] for c in self.say.calls], ["offline", "online"])

    def test_change_of_network(self):
        self.settle(("Cable", "802-3-ethernet"))
        self.assertEqual(self.say.calls, [("online", "Cable", "802-3-ethernet")])


class StatefulChecks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.state = nd.State(Path(self.tmp.name) / "s.json")
        self.say = Recorder()

    def test_updates_only_when_something_new(self):
        updates = nd.Updates.__new__(nd.Updates)
        updates.say, updates.state = self.say, self.state
        updates.report(["linux"], [])
        updates.report(["linux"], [])
        self.assertEqual(len(self.say.calls), 1)
        updates.report(["linux", "mesa"], ["zen"])
        self.assertEqual(len(self.say.calls), 2)
        updates.report([], [])
        updates.report(["linux"], [])                   # tras actualizar, una nueva vuelve a avisar
        self.assertEqual(len(self.say.calls), 3)

    def test_failed_units_notify_once(self):
        health = nd.Health.__new__(nd.Health)
        health.say, health.state = self.say, self.state
        health.report_failed("user", ["a.service"])
        health.report_failed("user", ["a.service"])
        self.assertEqual(self.say.calls, [("service_failed", "a.service", "user")])
        health.report_failed("user", [])
        health.report_failed("user", ["a.service"])
        self.assertEqual(len(self.say.calls), 2)


class Icons(unittest.TestCase):
    def test_every_icon_used_by_notifyd_exists(self):
        source = (ROOT / "notifyd.py").read_text()
        import re
        used = set(re.findall(r'icon="([a-z-]+)"', source)) | {"headphones", "mouse", "keyboard", "game"}
        used |= set(re.findall(r'"([a-z-]+)" (?:if|else) ', source)) & {i.split("/")[1] for i in gi.ICONS}
        known = {name.split("/")[1] for name in gi.ICONS}
        self.assertEqual(used - known, set())

    def test_accent_is_legible_on_any_palette(self):
        palettes = [
            {"background": "#0d1321", "foreground": "#dfe7f5", "color12": "#3a6ea5", "color13": "#5fa8d3"},
            {"background": "#171718", "foreground": "#E6CED3", "color12": "#52576C", "color14": "#B77381"},
            {"background": "#111111", "foreground": "#eeeeee", "color12": "#555555", "color13": "#333335"},
        ]
        for palette in palettes:
            colors, bg = gi.roles(palette)
            for role, color in colors.items():
                self.assertGreaterEqual(gi.contrast(color, bg), 4.5, f"{role} en {palette['background']}")

    def test_warm_wallpaper_does_not_tint_the_icons(self):
        warm = {"background": "#2a1a10", "foreground": "#f5d9b8", "color12": "#CA9681"}
        colors, bg = gi.roles(warm)
        self.assertEqual(bg, gi.GLASS)
        r, g, b = gi.to_rgb(colors["accent"])
        self.assertLess(r - b, 40)
        self.assertEqual(colors["muted"], gi.mix(gi.INK, gi.GLASS, 0.30))

    def test_missing_colors_file_uses_defaults(self):
        original = gi.COLORS
        gi.COLORS = Path("/nonexistent/colors.css")
        try:
            self.assertEqual(gi.read_palette(), gi.DEFAULT_PALETTE)
        finally:
            gi.COLORS = original


if __name__ == "__main__":
    unittest.main()
