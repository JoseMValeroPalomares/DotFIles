# Plan de auditoría y mejora — Hyprland (config Lua)

Diagnóstico: 2026-10-20 · Estado actualizado: 2026-10-20 (fin de la sesión 1)

## Contexto verificado

- Versión instalada: **Hyprland 0.56.2** (paquete `hyprland 0.56.2-4`), no 0.57. Todo se valida contra
  `/usr/share/hypr/stubs/hl.meta.lua`, la config de ejemplo `/usr/share/hypr/hyprland.lua`,
  `hyprctl descriptions` y pruebas inocuas en vivo.
- Config activa: `hyprland.lua`. Los `*.conf` de Hyprland (hyprland.conf, configs/*.conf, UserConfigs/*.conf,
  monitors.conf…) **no se cargan**. hypridle.conf / hyprlock.conf sí (son de otras herramientas).
- Wallust genera `wallust/wallust-hyprland.lua` (plantilla `colors-hyprland.lua`) → integración correcta.
- Equipo: portátil **MSI** (touchpad `msnb0001:00-06cb:7e7e-touchpad`, `mcontrolcenter`), sin `asusctl`.
  Monitores eDP-1 y HDMI-A-1, 1920×1080, ambos admiten 60 y 144 Hz. `powerprofilesctl` disponible.

### Lo aprendido de la API Lua de 0.56 (probado en vivo)

- `hyprctl keyword` no funciona ("Use eval"). `hyprctl dispatch` espera una expresión Lua:
  `hyprctl dispatch 'hl.dsp.dpms("on")'`. Para config en caliente: `hyprctl eval 'hl.config({...})'`.
  Para leer valores: `hyprctl repl 'return ...'`.
- `hyprctl reload` **recrea la VM de Lua**: se pierden globales y estado de módulos. `hyprctl eval 'require("configs.X")'`
  comparte los módulos cargados por la config.
- `hl.bind(keys, function() ... end, opts)` admite funciones. `hl.get_config("a.b")` / `hl.config({a={b=v}})` en runtime funcionan;
  los gaps vuelven como tabla `{left,top,right,bottom}` y se pueden reinyectar tal cual.
- `hl.dsp.group.active({ index = N })`: índice **base 1**.
- `hl.dsp.window.float({ action = "enable"|"disable"|"toggle", window = "address:0x…"|"class:…" })`
  (valor desconocido = toggle).
- `hl.exec_cmd(cmd, { workspace = "special:x silent", float = true, ... })` aplica reglas al lanzar.
- Reglas de ventana: `size`/`move` como string `"monitor_w*0.65 monitor_h*0.65"` o tabla de expresiones;
  los **porcentajes (`"72%"`) no funcionan**. kitty pide abrirse maximizado → `suppress_event = "maximize"`.
- `hl.window_rule({...})` devuelve un objeto con `:set_enabled(bool)`; tras cambiarlo,
  `hl.exec_scheduled_prop_refresh_immediately()`. Opacidad real: `hyprctl getprop address:0x… opacity_inactive`.
- `hl.get_monitors()[i].available_modes` → `{ width, height, refresh_rate, preferred }`.
- Los constructores `hl.dsp.*` **no validan claves** (aceptan `{ foo = 1 }`); hay que probar con efecto real.
- Técnica de prueba segura: abrir `kitty --class hyprtest` con `hl.exec_cmd(..., { workspace = "special:hyprtest silent" })`,
  probar sobre ella y cerrarla con `hl.dsp.window.close({ window = "class:hyprtest" })`.
- `hyprctl descriptions` muestra `current` poco fiable; usar `hyprctl getoption`.

## Decisiones del usuario (no reabrir)

- No tocar: SUPER+1..0, SUPER+arrastrar, SUPER+Tab, `/bin/mi_script_captura.sh`,
  (hypridle.conf: solo se corrigió dpms con permiso, 2026-10-21) ni `tag = terminal` en `UserConfigs/UserSettings.lua`.
- Jarvis y SUPER+J: eliminados; SUPER+J no se reasigna a nada.
- Estética (bordes, gaps, sombras, blur, colores): **se queda como está**. Solo se pulieron animaciones (hecho).
- Modo juego: menú con juego/ahorro y 60/144 Hz; al desactivar, restaurar todo exactamente (hecho).

## Hecho en la sesión 1 → ver PROGRESS.md

Prioridad 1 completa salvo lo que el usuario decidió no tocar.

## Pendiente

### Prueba del usuario (preguntar al empezar)
- Modo juego / ahorro (SUPER+ALT+G): cambio real a 60 Hz y vuelta a 144 Hz, perfil de energía restaurado.
- Tecla de touchpad (xf86TouchpadToggle): desactiva y reactiva.

### Prioridad 2 — Obsoleto / incorrecto
- Regla **Picture-in-Picture** (`configs/WindowRules.lua`): `move = {"72%", "7%"}` no funciona →
  `move = "monitor_w*0.72 monitor_h*0.07"`.
- Reglas duplicadas/contradictorias en `configs/WindowRules.lua`: `idle_inhibit` ×2, float de Steam/Heroic ×2,
  `games` ×2, opacidad de `multimedia` definida 3 veces, opacidades sobrescritas por `UserSettings.lua`,
  tag `KooL_Settings` vs `KooL-Settings`, regex `^(jetbrains-*)`, regex de notif con `|class`. (hecho, 2.2 + 2.11)
- `configs/Laptops.lua`: binds xf86Launch1/3/4 llaman a `asusctl`/`rog-control-center` (no instalados).
  Preguntar si quiere quitarlos o reasignarlos (p. ej. a `mcontrolcenter`).
- Variables rotas `local scriptsDir = "os.getenv(\"HOME\")/…"` en `configs/Startup_Apps.lua`,
  `configs/Laptops.lua`, `UserConfigs/UserKeybinds.lua` (código muerto engañoso).
- Menús/scripts que leen o escriben `.conf` que ya no se cargan: ~~`Animations.sh`~~ (hecho, 2.7),
  ~~`KeyBinds.sh`~~ (hecho, 2.8; `keybinds_parser.py` sin uso → legacy), ~~`Kool_Quick_Settings.sh`~~ (hecho, 2.9),
  ~~`MonitorProfiles.sh`, `nwg-displays`~~ (2.9: MonitorsConfig.sh; MonitorProfiles.sh y RainbowBorders → legacy). Revisar uno a uno.
- `dbus-update-activation-environment` + `systemctl --user import-environment` al arrancar: redundantes.
- `HYPRCURSOR_SIZE` definida dos veces; `cursor.warp_on_change_workspace = 2` anulado por `no_warps = true`.
- ~~14 scripts usan `pkill rofi`~~ (hecho, 2.10: `pkill -x rofi`).

### Prioridad 3 — Rendimiento (sin quitar funciones)
- ~~`FixPortals.sh`~~ (hecho, 3.1: fuera del autoarranque; el script irá a legacy/).
- ~~`sleep 3` de waybar/swaync~~ (hecho, 3.2).
- ~~`qs -c overview` residente~~ (hecho, 3.3: bajo demanda; además arreglado el overview).
- (Zoom, layout, blur y dropterminal ya están en Lua sin procesos.)

### Prioridad 4 — Visual
- Cerrada por decisión del usuario (solo animaciones, ya hechas).

### Prioridad 5 — Limpieza y organización
- Mover (no borrar) a `legacy/`: `.conf` de Hyprland, `WindowRules-pre-53.*`, `WindowRules-config-v3.*`,
  Añadir: `MonitorProfiles.sh`, `Monitor_Profiles/`, `keybinds_parser.py`, `DarkLight.sh` (entero comentado, no hace nada).
  `wallust/wallust-hyprland.conf`, `RainbowBorders.bak.sh`, `off_*.sh`, `Dropterminal.sh`, `ChangeLayout.sh`,
  `KeybindsLayoutInit.sh`, `Tak0-Autodispatch.sh` (nadie los llama), solo tras comprobar que ningún script los usa.
- ~~Fusionar reglas fragmentadas~~ (qalculate en 2.2; cronómetro quitado en 5.3).
- ~~Un único módulo con rutas~~ (hecho, 5.3: `configs/Paths.lua`).

## Método

1. Un bloque cada vez; commit pequeño por bloque (repo git local en `~/.config/hypr`, sin remoto).
2. Validación: `hyprctl reload` → `hyprctl configerrors` → prueba del bind/función → `hyprctl rollinglog | tail` si falla.
3. Rendimiento: `ps -o rss,pcpu -C Hyprland` antes/después.
4. Reversión: `git revert <commit> && hyprctl reload`, o `tar -xzf ~/hypr-backup-2026-10-20.tar.gz -C ~/.config`.

---

# Hyprlock (2026-10-21)

Versión **hyprlock 0.9.6**. Monitores eDP-1 y HDMI-A-1, 1920×1080, escala 1.
Validar sin bloquear: `hyprlock -v --display wayland-noexiste` (lee la config, muestra errores y sale).
Desbloqueo de emergencia desde una TTY: `pkill -USR1 hyprlock`; si sale la pantalla de «lockscreen died»:
`hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'`.
**Ojo:** desbloquear con SIGUSR1 con PAM activo cuenta como intento fallido en faillock (deny=3).
**No** volver a usar un Hyprland anidado para capturas (ver H3).

## Decisiones del usuario
- Se mantiene la disposición en dos columnas (login a la izquierda, información a la derecha), pero pulida.
- Todos los widgets en ambos monitores (como ahora).
- Fondo: menú propio (como el del wallpaper) con opción «aleatorio».
- Colores: plantilla de Wallust propia para hyprlock.

## Fases
1. [x] Contraseña y colores (Wallust, colores de reserva, opciones que no existen en 0.9).
2. [x] Estética + menú de fondo de hyprlock con aleatorio.
3. [x] Alineación de módulos.
4. [x] Rendimiento (intervalos de `update`, blur, general/animations).
5. [x] Robustez (timeouts en scripts, auth, grace).

6. [x] hypridle.conf (autorizado por el usuario el 2026-10-21): `hyprctl dispatch dpms on|off` fallaba en 0.56.
   Probado en vivo: `hl.dsp.dpms("on")`, `("off")`, `("enable")`… ALTERNAN; solo la tabla es idempotente:
   `hl.dsp.dpms({ action = "on" | "off" })`. Añadido `inhibit_sleep = 3`.

---

# Auditoría de scripts y menús de Rofi (2026-10-21)

Alcance: `hypr/scripts`, `hypr/UserScripts`, `waybar/scripts` (solo los scripts, no su config), `~/.local/bin/{brillo,screenshot-ocr}`
y `~/.config/rofi`. Inventario completo y clasificación propuesta: `INVENTARIO.md`.
Copia: `~/backup-scripts-2026-10-21.tar.gz` (2191 entradas). Git: hypr 5424aad (estado previo), rofi f4c43ea (nuevo repo).
Rofi 2.0.0 oficial (Wayland nativo). Herramientas instaladas para la auditoría: shellcheck, shfmt, hyperfine
→ **desinstalar al terminar** las que no se usen (`sudo pacman -Rns …`).
Ojo: la shell puede quedarse con una firma de Hyprland antigua tras un reinicio → `hyprctl -i 0`.

## Decisiones del usuario (no reabrir)
- Archivar en `legacy/` del propio directorio (hypr/legacy, waybar/legacy, rofi/legacy), nunca borrar.
- Archivar: ZshChangeTheme (+ atajo), Kitty_themes (+ entrada de QS), sddm_wallpaper (sddm desinstalado, + entrada de QS),
  WallpaperAutoChange, waybar/scripts/contraste.py.
- RofiEmoji: mejorado. RofiThemeSelector: QUITADO por el usuario (antes «mantener»); SUPER+CTRL+R libre.
- Rofi: la transparencia de los menús y del lanzador SE QUEDA como está (decisión 2026-10-21; los 4 ya opacos también).
  Excepción pedida: la calculadora al 96 % (config-calc.rasi; el usuario lo subió del 92 %).
  Temas: los 9 sin wallust archivados en ~/.config/rofi/legacy/themes.
- Uso ocasional: RofiBeats. En uso: RofiSearch (SUPER+SHIFT+O). WaybarCava archivado (no lo usa).
- KeyboardLayout: atajo comentado hasta que haya otra distribución; no reabrir.

## Fases
1. [x] Inventario (INVENTARIO.md) + primer shellcheck: 5 errores y 40 avisos en 18 scripts.
2. [x] Clasificación confirmada y archivado (ver PROGRESS).
3. [ ] Arreglos: WallpaperSelect, Volume, KeyboardLayout, RofiThemeSelector (fusión), el resto por uso.
4. [ ] Rendimiento (hyperfine antes/después).
5. [ ] Rofi: tema base único con wallust, temas sin uso, apertura.
6. [x] Validación final (falta que el usuario desinstale las herramientas).

## Proyectos aparcados

- **hyprplane (plano infinito solo en el workspace 10)**: desactivado y limpio. Contexto y cómo retomarlo en
  `experiments/hyprplane/CLAUDE.md`. El usuario quiere cambiar y arreglar cosas (preguntarle cuáles al retomarlo).
