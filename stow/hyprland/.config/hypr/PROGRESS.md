# Progreso

## Cómo retomar
1. Leer `PLAN.md` (contexto, API aprendida, decisiones del usuario, pendiente) y `git log --oneline`.
2. Preguntar al usuario por las pruebas pendientes: modo juego a 60/144 Hz y tecla de touchpad.
3. Seguir con **Prioridad 2**, empezando por la regla Picture-in-Picture y las reglas duplicadas.
   Un bloque cada vez, validar y commit.

## Sesión 1 — 2026-10-20
- [x] Inventario y diagnóstico completo (ver PLAN.md).
- [x] Paso 0: backup en `~/hypr-backup-2026-10-20.tar.gz` (155 entradas) + git init (commit 1dd5284)
- [x] Eliminado Jarvis: bind SUPER+J y 4 reglas de ventana (.lua y .conf).
- [x] 1.3 swww: quitado `&& swww restore` inalcanzable (se nota al próximo login)
- [x] Animaciones estilo macOS (`UserConfigs/UserAnimations.lua`): curvas macOut/macIn/macMove/macSpaces,
      cierre más corto que apertura, capas con animación propia (antes heredaban 800 ms), sin animaciones en bucle.
- [x] 1.6 Zoom en Lua puro (`configs/Zoom.lua`): SUPER+SHIFT+rueda (×2) y gestos 4 dedos (×1.5). Límites 1–10.
- [x] Nuevo: SUPER+CTRL+rueda = zoom fino (×1.25 / ×0.8); la cámara sigue al ratón
      (`zoom_detached_camera = false`, `zoom_rigid = false`). Usuario: funciona bien.
- [x] 1.4 CTRL+ALT+Del → `hl.dsp.exit()` (no ejecutado: cerraría la sesión)
- [x] 1.10 SUPER+ALT+1..8 → `hl.dsp.group.active({ index = N })`
- [x] 1.5 SUPER+ALT+SPACE → función Lua que flota/desflota todo el workspace
- [x] 1.7 SUPER+ALT+L → toggle dwindle/master en Lua, sin J/K; quitado `ChangeLayout.sh init` del arranque
- [x] 1.9 Terminal desplegable nativa (SUPER+SHIFT+Return): special:dropterm + regla "dropterm" en
      `UserConfigs/WindowRules.lua`; se abre al primer uso. Usuario: funciona bien.
- [x] Modo juego / ahorro (SUPER+ALT+G o Quick Settings): `configs/GameMode.lua` + `scripts/GameMode.sh`.
      Menú rofi juego/ahorro × 60/144 Hz, powerprofilesctl, restauración exacta sin reload (diff idéntico
      de 11 ajustes). Estado en `$XDG_RUNTIME_DIR/hypr-gamemode`.
- [x] 1.8 ChangeBlur.sh → `hyprctl eval` (sin efecto visible: blur desactivado en la config)
- [x] 1.13 Touchpad: nombre real en `configs/Laptops.lua`; `TouchPad.sh` autodetecta y usa eval
## Sesión 2 — 2026-10-20
- [x] 2.1 Regla Picture-in-Picture: `move` con expresiones (antes "72%" se ignoraba); quitada opacidad duplicada.
      Probado: ventana en (72 %, 7 %) del monitor, flotante, fijada, 30 %.
- [x] 2.2 Reglas duplicadas fuera (12 líneas): idle_inhibit, float Steam/Heroic, games, qalculate fusionada,
      opacidades de projects/im/multimedia/file-manager/settings/viewer (las anulaba UserSettings.lua).
      La de terminal se queda: es la que se aplica (la de UserSettings usa `tag = terminal` sin comillas).
      Probado: propiedades idénticas antes/después en 10 clases (opacidad, flotante, no_blur).
- [x] Usuario confirma: modo juego 60/144 Hz y tecla de touchpad funcionan.
- [x] 2.3 Quitadas las teclas xf86Launch1/3/4 de `configs/Laptops.lua` (asusctl/rog-control-center no instalados).
- [x] 2.4 `scriptsDir`/`UserScripts` en Startup_Apps, Laptops y UserKeybinds: ahora ruta real (antes texto literal).
- [x] 2.5 `HYPRCURSOR_SIZE` solo en UserConfigs/ENVariables.lua (estaba duplicada con el mismo valor).
- [x] 2.6 Quitados `dbus-update-activation-environment` y `systemctl --user import-environment` del autoarranque:
      Hyprland ya los ejecuta él mismo (verificado en el binario). Pendiente: confirmar en el próximo login.
- [x] Warp al cambiar de escritorio: `warp_on_change_workspace = 2` (force) ignora `no_warps`; usuario confirma que salta. Sin cambios.
- [x] 2.7 Menú de animaciones (SUPER+SHIFT+A) reconstruido: 17 presets traducidos a `animations/*.lua`
      + `animations/macOS.lua` (por defecto). `UserAnimations.lua` carga el elegido (`UserConfigs/AnimationPreset`,
      fuera de git) y vuelve a macOS si falla. Aplica con reload; bloqueado con modo juego activo.
      Ajustes: borderangle 180→100 (máximo de Hyprland) en 3 presets; curva "nice" fuera de rango omitida (sin uso).
      Probado: los 18 presets sin errores y con sus curvas aplicadas; menú con rofi simulado (elegir, marcar activo,
      cancelar, preset inexistente, modo juego).
- [x] kitty (SUPER+Return) se abría maximizada y tapaba las demás: regla `kitty-no-maximize` (suppress_event).
      Probado: 3 terminales seguidas entran en mosaico (antes fs=1); SUPER+CTRL+F sigue maximizando.
- [x] Terminal desplegable: animación nueva en `animations/macOS.lua` (specialWorkspaceIn/Out, `slidefadevert -8%`):
      cae un poco desde arriba con fundido y se va subiendo. Antes `slidevert` la subía desde abajo una pantalla entera.
      Probado con capturas a cámara lenta. `no_anim` en la regla dropterm: escondida en un monitor y abierta en el otro cruzaba volando (windowsMove);
      ahora aparece en su sitio. Probado con capturas a cámara lenta (la primera prueba no cambiaba de monitor por un fallo mío).


- [x] Restaurados `~/.config/rofi/config.rasi` (1 línea, estaba repetida ×24) y `~/.config/kitty/kitty.conf` (quitado
      `include ./kitty-themes/Broadcast.conf` que dejó la prueba de Ajustes rápidos); kitty recargado, fondo #000000 otra vez.

- [x] 2.10 `pkill rofi` → `pkill -x rofi` en 13 scripts + `configs/Keybinds.lua` (SUPER+D, SUPER+CTRL+SHIFT+R).
      Antes también apuntaba a power-profiles-daemon (PID 806). Probado: cierra rofi, el servicio sigue y el perfil también.
      Los `.conf` sin cargar no se tocan (irán a legacy/).

- [x] 2.11 `configs/WindowRules.lua`: tag `settings` → `settings` (ahora flota y se centra como nwg-look), centrado
      duplicado fuera, `^(jetbrains-*)` → `^(jetbrains-.+)$`, `|class` fuera de la regla notif. Ninguna app actual afectada.
      Probado con kitty de prueba: título de ajustes → flotante con tag settings; clase "class" ya no recibe notif.

- [x] 3.1 `FixPortals.sh` fuera del autoarranque: el journal muestra que systemd ya arrancaba los portales bien y el script
      los mataba (KILL) para que systemd los relanzara. Probado: portal responde (Settings, ScreenCast). Pendiente: confirmar en el próximo login.

- [x] 3.2 Sin `sleep 3` para waybar y swaync. swaync ya lo activaba D-Bus antes (journal). Probado: waybar relanzado sin espera
      en ambos monitores, bandeja OK. Pendiente: confirmar en el próximo login.

- [x] 3.3 Overview (SUPER+A, `~/.config/quickshell`, repo git propio + `~/quickshell-backup-2026-10-20.tar.gz`):
      5 órdenes `Hyprland.dispatch` pasadas a `hl.dsp.*` (clic, arrastrar, cerrar, cambiar escritorio fallaban).
      `OverviewToggle.sh` buscaba `quickshell` (el proceso es `qs`) → cada SUPER+A arrancaba otra copia (~300 MB). Ahora
      `qs -n -d` + IPC; sale del autoarranque (arranque en frío ~150 ms). Probado: 5 pulsaciones, 1 sola copia.

- [x] 3.4 Overview mejorado (repo `~/.config/quickshell`): solo en el monitor donde se abre; fila de arriba = escritorios
      de ese monitor, abajo los del otro (leído de `hyprctl workspacerules`); marco en el activo de cada monitor;
      teclas 1-0 saltan y cierran; flechas por la cuadrícula; colores de wallust (plantilla `quickshell-overview.json`,
      `wallust.toml` con copia `.bak-2026-10-20`) con recarga en vivo; restos sin uso a `legacy/`.
      `Refresh.sh`/`RefreshNoWaybar.sh`: `pkill qs && qs &` lanzaba qs sin config → `pkill -x qs`.
      Probado en ambos monitores con capturas. Pendiente del usuario: clic, arrastrar, clic central, flechas y 1-0.

- [x] 5.1 51 archivos sin uso a `legacy/` (misma estructura, ver legacy/README): .conf de Hyprland, WindowRules-pre-53/config-v3,
      presets .conf de animaciones, hyprlock-2k, wallust-hyprland.conf, Monitor_Profiles, MonitorProfiles.sh, keybinds_parser.py,
      Dropterminal, ChangeLayout, KeybindsLayoutInit, FixPortals, off_*, Tak0-Autodispatch, RainbowBorders.bak.
      `ThemeChanger.sh` esperaba hasta 10 s a wallust-hyprland.conf (ya no se genera) → .lua.
      Se quedan (aún los lee algún script): 01-UserDefaults.conf, UserConfigs/Startup_Apps.conf, configs/SystemSettings.conf, DarkLight.sh.

- [x] 5.2 Últimos lectores de .conf pasados a Lua: WaybarScripts.sh y RofiSearch.sh leen term/files/searchEngine con
      `hyprctl repl` (y la búsqueda ya sustituye `{}`; antes buscaba "{}consulta"). Tak0-Per-Window-Switch.sh lee
      `input:kb_layout`; con una sola distribución sale sin notificar; sin socat no lanza la escucha.
      Fondo de vídeo: WallpaperSelect.sh guarda `UserConfigs/LiveWallpaper` y Startup_Apps.lua lanza mpvpaper o swww
      (mpvpaper no está instalado: preparado, no probado en real). Waybar: quitado el clic de DarkLight
      (`~/.config/waybar/ModulesCustom`, copia `.bak-2026-10-20`). A legacy/: 01-UserDefaults.conf,
      UserConfigs/Startup_Apps.conf, configs/SystemSettings.conf, DarkLight.sh. Probado con programas falsos.

- [x] 5.3 Quitadas las 3 reglas del cronómetro. Rutas en un único sitio: `configs/Paths.lua` (hypr, scripts, userScripts,
      userConfigs, animations); 8 archivos lo usan. Fuera las variables rotas (`"os.getenv(\"HOME\")/…"`: UserConfigs ×2, wallDIR).
      Probado: config cargada con Hyprland simulado antes/después → 242 órdenes idénticas; 164 atajos idénticos tras reload.

- [x] 5.4 Teclado 60 %: SUPER+ALT+Alt_R = intercambiar con la izquierda, SUPER+ALT+Control_R = con la derecha
      (las flechas siguen). FN+SUPER es el «Win Lock» del teclado, no de Hyprland. Pendiente: probar con el teclado real.

- [x] 5.5 Intercambio de ventanas con pantalla completa: `configs/WindowSwap.lua` guarda el modo (maximizado/completa) de las
      ventanas visibles, lo quita, intercambia y lo restaura. Los 6 atajos de swap lo usan. Usuario: funciona perfectamente.

- [ ] Prioridad 2 · [ ] Prioridad 3 · [ ] Prioridad 5 (Prioridad 4 cerrada por decisión del usuario)

## Hyprlock

- [x] H1 Puntos de la contraseña invisibles: el `source` apuntaba a `wallust/wallust-hyprland.conf` (movido a legacy/ en 5.1)
      → `$foreground`/`$color13` sin definir → `font_color` por defecto casi negro sobre la caja negra. 16 errores en el log.
      Nueva entrada `hyprlock` en `~/.config/wallust/wallust.toml` (copia `.bak-2026-10-21`) que reutiliza la plantilla
      `colors-hyprland.conf` → `wallust/wallust-hyprlock.conf`. Colores de reserva antes del source.
      Quitados `general:grace` y `input-field:fail_timeout` (no existen en 0.9). Puntos 0.3 redondos, check/fail/capslock y
      `fail_text` con intentos. Validado: 0 errores de config. Pendiente: prueba real del usuario.
- [x] H2 Estética y fondo propio. `UserScripts/HyprlockBackground.sh` (SUPER+CTRL+U): menú rofi (mismo tema que el de
      wallpapers) con «Aleatorio», «Escritorio» (= `.wallpaper_current`) o una imagen; estado en `UserConfigs/HyprlockBackground`.
      hyprlock lee los enlaces `~/.cache/hyprlock/background` y `colors.conf`. Los colores de un fondo propio salen de wallust
      con config aislada (`-d ~/.cache/hyprlock/wallust`, `-s`): no toca el tema del escritorio ni `sequences` (0,6 s).
      Aleatorio: un label oculto lanza `--next` al bloquear; espera 5 s (fondo ya cargado) y prepara el del próximo bloqueo;
      `flock` para que con 2 monitores actúe una sola copia (probado). Plantilla nueva `colors-hyprlock.conf` con
      `$accent_soft`, `$accent_glow`, `$surface`. Avatar `profile-lock.png` 300×300 recortado a la cara (original intacto).
      Blur 3→2 pasadas, brillo 0,6, sombras negras suaves, superficies con el fondo de la paleta, pesos de fuente.
      Validado: 0 errores de config, 0 de Hyprland, menú abre en 123 ms. Pendiente: prueba real del usuario.
      `hyprlock.png` ya no se usa (candidato a legacy/).
- [x] H3 Alineación (1920×1080, escala 1). Columna izquierda x=120, ancho 320: logo y avatar en la misma fila (y=145),
      avatar con el borde derecho en 440 como las cajas; 40 px hasta la caja de usuario, 20 px entre cajas.
      Columna derecha con borde en -120: hora (y=145, a la altura del avatar), fecha y clima (text_align right) debajo.
      Abajo: Spotify a la izquierda y batería · tiempo encendido a la derecha en la misma línea base (y=65).
      Logo con `JetBrainsMono Nerd Font Propo` (sin fuente/Mono el icono salía cortado). Fecha en español
      (`LC_TIME=es_ES.UTF-8`, mayúscula inicial). `UserScripts/HyprlockStats.sh`: batería y uptime en español, solo builtins
      (6 ms). `scripts/spotify.sh` no era ejecutable (la caja salía vacía) → +x. `hyprlock.png` → legacy/.
      Verificado con capturas reales (Hyprland anidado + salida headless; config de prueba sin PAM).
      **Incidente:** a las 12:38:06 el Hyprland principal salió y falló al cerrar (SIGSEGV en Aquamarine
      CDRMBackend::flushAsyncCommitEvents dentro de exit); start-hyprland lo relanzó. Causa no confirmada; antes hubo un
      «Restoring after VT switch» que pudo provocar el anidado. Además, una prueba con PAM activo dejó 1 fallo en faillock
      (borrado con `faillock --reset`). Pendiente: prueba real del usuario.
- [x] H4 Rendimiento. Cada label con `cmd[]` se ejecuta una vez por monitor (2). Antes: batería y Spotify cada 1 s
      ≈ 16 procesos/s; ahora: Spotify 3 s, batería/uptime 30 s, fecha 60 s (antes 12 h: no cambiaba a medianoche),
      clima 5 min (antes 1 h; LockScreen.sh lo refresca al bloquear) ≈ 3 procesos/s (−80 %).
      `spotify.sh`: una sola llamada a playerctl con `timeout 1` (antes 2 sin límite) y escape de & < > para Pango
      (ojo: en bash 5.2 `&` en el reemplazo de ${//} es el texto encontrado → `\&`). Probado con playerctl falso.
      general: `hide_cursor = true`, `ignore_empty_input = true`. Bloque `animations` corto (fadeIn 300 ms).
      `--next`: como mucho un cambio de fondo por minuto aunque hyprlock repitiera el comando. Validado: 0 errores.
- [x] H4b Medido en real (2 monitores, ~35 s): 8 % CPU, 301 MB RSS. En reposo cada actualización = 1 fotograma, pero
      los primeros ~5,3 s redibujaba sin parar a 143 fps (753 fotogramas por monitor): el `--next` heredaba una copia de la
      tubería con la que hyprlock lee la salida del label y hyprlock esperaba su EOF (el `sleep 5`). `--next` cierra los
      fd > 2 al empezar. Simulado: espera del lector 3006 ms → 4 ms; con el script real 14 ms. Autenticación OK, 0 ERR/WARN,
      `update:0` confirmado: 1 ejecución por monitor. Pendiente: repetir la medida.
- [x] H5 Robustez. `auth {}` explícito (PAM «hyprlock» → login; sin huella). Grace: sin cambios (0, ningún lanzador lo
      pasa; hypridle.conf no se toca). Todos los cmd terminan solos: date/cat, HyprlockStats (builtins), spotify
      (`timeout 1`), --next desacoplado. Simulado sin caché ni paleta: solo errores de `source`, colores de reserva OK.
      `scripts/HyprlockCheck.sh`: valida la config y los recursos sin bloquear (los abortos quedan con Storage: none).
      `hyprlock-rescate.txt`: chuleta para la TTY (USR1, clear_crashed_lockscreen, faillock, revertir con git).
      Prueba real del usuario: puntos visibles, fluido. Hallado: dpms de hypridle.conf roto en 0.56 (ver PLAN).
- [x] H6 hypridle.conf (con permiso): las 5 órdenes `hyprctl dispatch dpms on|off` fallaban en 0.56 («')' expected») →
      las pantallas nunca se apagaban bloqueado. Probado en vivo con dpmsStatus: los argumentos de texto ("on", "off",
      "enable", "disable") ALTERNAN; `{ action = "on"|"off" }` es idempotente. Ejecutadas las líneas tal cual con `sh -c`:
      apagar, encender y after_sleep_cmd OK. `inhibit_sleep = 3`. hypridle reiniciado (1 instancia, inhibidor activo).
      Copia: hypridle.conf.bak-2026-10-21.
- [x] H7 Bloqueo en un solo monitor (petición del usuario): HDMI si está activo, si no eDP-1; el otro negro liso.
      `scripts/HyprlockMonitor.sh` (9 ms) escribe `~/.cache/hyprlock/monitor.conf` ($LOCK_MONITOR, $LOCK_OTHER) y lo
      llama `lock_cmd` de hypridle: `pidof hyprlock || (HyprlockMonitor.sh; hyprlock)`. Los 13 widgets usan $LOCK_MONITOR;
      fondo negro para $LOCK_OTHER («none» = no existe → se ignora). Si falta o falla: $LOCK_MONITOR vacío = todos.
      Probado: HDMI+eDP, solo eDP, solo HDMI, hyprctl fallando, lock_cmd con sh -c. Bonus: los cmd se ejecutan 1 vez, no 2.
      Limitación: si se desconecta el HDMI con la pantalla ya bloqueada, la contraseña se escribe a ciegas (funciona).

## Auditoría de scripts — 2026-10-21
- [x] Fase 0/1: copia `~/backup-scripts-2026-10-21.tar.gz`, git en rofi, inventario en `INVENTARIO.md`, shellcheck (5 E, 40 avisos).
- [x] Fase 2a · Archivado (git mv a `legacy/`): hypr → sddm_wallpaper, RefreshNoWaybar, Polkit-NixOS, UptimeNixOS, PortalHyprland,
      UserConfigsSwitcher, Battery, Tak0-Per-Window-Switch, Tak0-Autodispatch, ZshChangeTheme, WallpaperAutoChange.
      rofi → config-zsh-theme, config-keybinds, config-Monitors, 0-shared-fonts, config-clipboard.rasi.bak. waybar → contraste.py.
      Quitados: atajos SUPER+SHIFT+O (zsh) y SHIFT_L+ALT_L (Tak0), entrada SDDM de Ajustes rápidos y su regla de ventana.
      Se quedan (cambio sobre lo propuesto): Kitty_themes (usuario), KeyboardLayout.sh y Hypridle.sh (los usan módulos de
      Waybar de otras barras elegibles con WaybarLayout). Probado: reload sin errores, 166 atajos, Ajustes rápidos con rofi falso.
- [x] RofiSearch con atajo SUPER+SHIFT+O (antes no tenía ninguno; el comentario decía SUPER+S, que es el OCR). Probado con rofi/xdg-open falsos.
- [x] 3.1 WallpaperSelect.sh: elige por número de fila (`-format i`) → archivo exacto. Antes buscaba por nombre sin extensión
      y con 8 nombres repetidos (space.jpg/space.png…) aplicaba otro; nombres con ' rompían `xargs`. Quitados 807 `basename`
      (uno por fondo), 3 → 1 llamadas a hyprctl, `bc` (ahora awk), IFS global, variables sin uso, `sleep 2` + `sleep 1`
      (WallustSwww.sh ya espera a las plantillas) y espera real al daemon de swww. Carpeta vacía: aviso en vez de error.
      Apertura del menú: 795 → 52 ms (hyperfine). Aplicar: −3 s. shellcheck limpio. Probado con swww/wallust falsos.
- [x] 3.2 awww directamente (swww era un enlace a mano a awww, sin paquete): WallpaperSelect, WallpaperRandom, WallpaperEffects,
      WallustSwww (consulta + caché `~/.cache/awww/<versión>/`; la de swww estaba parada desde abril), Startup_Apps (awww-daemon) y KeyHints.
      El daemon se detecta con `awww query` (vale para el swww-daemon que corre hasta el próximo login). Ayuda: SUPER+U / SUPER+SHIFT+U.
      WallpaperRandom rehecho: con el daemon caído lo lanzaba en primer plano y se colgaba; nombres con espacios se partían; sin sleep 2.
      Probado con awww falso (daemon vivo y caído) y la caché real.
- [x] WaybarCava.sh → legacy/ (usuario no lo usa). Módulo custom/cava_mviz fuera de ModulesCustom y de 11 barras de waybar
      (no estaba en la activa, configs/2). JSONC validado antes/después. Paquete `cava` aún instalado: candidato a desinstalar al final.
- [x] 3.3 Volume.sh (teclas de volumen/micro y Waybar): pamixer cambia y lee en una sola llamada → 1–2 llamadas por pulsación
      (antes 2–6); Sounds.sh en segundo plano (antes bloqueaba ~150 ms en cada pulso con la tecla mantenida).
      Pulsación: ~190 → ~10 ms (simulado). Notificaciones en español y todas con la misma etiqueta (silenciar ya no se apila).
      Mismo comportamiento: silenciado + subir = reactivar, límite 150 %, salidas de --get/--get-icon iguales
      (salvo nivel 0 → icono de silencio). Comparado antiguo/nuevo en 18 casos con pamixer falso. shellcheck limpio.
- [x] Atajo ALT+SHIFT de KeyboardLayout.sh comentado (solo hay "us"; decisión del usuario: reactivar al instalar otra distribución).
      El script se queda: lo usan módulos custom/keyboard de otras barras de Waybar. Pendiente de arreglar su error de shellcheck (línea 88) si se reactiva.
- [x] BrightnessKbd.sh → legacy/ (usuario no la usa); quitadas las teclas xf86KbdBrightnessUp/Down de configs/Laptops.lua. 164 atajos.
- [x] 3.4 Brightness.sh: lectura sin cut/tr, aviso en español («Brillo · 47 %») que se ve con «No molestar» (como el volumen),
      sin variable sin uso. Mismo resultado en 7 casos (límites 5–100 %, iconos) con brightnessctl falso. Velocidad igual (~24 ms).
      Nota: `brightnessctl --min-value` NO limita un `set` absoluto (probado) → el 5 % se calcula en bash.
- [x] 3.5 `~/.local/bin/brillo` (del usuario, terminal; fuera de git): sin `sudo` (ddcutil funciona con la ACL de la regla udev
      60-ddcutil-i2c.rules; antes pedía contraseña), `brillo` solo = muestra ambos, +N/-N relativos, validación 0–100,
      errores claros si el monitor no responde, código de salida ≠0 si algo falla. Probado con +0 (sin cambios reales),
      6 entradas no válidas y ddcutil falso. Original: `tar -xzf ~/backup-scripts-2026-10-21.tar.gz -C ~ .local/bin/brillo`.
- [x] 3.6 Refresh.sh (tras cada fondo/tema/diseño de Waybar y SUPER+ALT+R): ya no mata swaync (lo gestiona systemd; se perdía
      el historial) → `swaync-client --reload-css/--reload-config`; SIGUSR1 solo a kitty (antes también a waybar = ocultar barra,
      rofi, swaync, swaybg); Waybar se reinicia esperando a que la anterior termine + `setsid -f`; fuera ags, RainbowBorders y
      ~2 s de sleeps. Probado real: 83 ms, 1 Waybar en eDP-1 y HDMI-A-1, swaync mismo PID, kitty ×3 vivas, journal limpio.
- [x] 3.7 Sounds.sh: sin cat|grep|cut ni hasta 4 find (bash + glob), `exec` del reproductor, `--error` con su propio interruptor
      (antes lo silenciaba muteScreenshots), sin ruta de NixOS. Mismos archivos en los 3 sonidos; 11 → 3 ms antes de reproducir
      (con pw-play falso). shellcheck limpio.
- [x] 3.8 ScreenShot.sh (Imprimir/F6 y SUPER+SHIFT+S): cancelar la zona con Esc ya no avisa «NOT Saved» con sonido de error
      ni deja un temporal; swappy borra su temporal al terminar; botones Abrir/Borrar activos los 10 s que dura el aviso (antes 5);
      sin `sleep 2`/`sleep 1` tras capturar; ventana activa también al portapapeles y clase apta para nombre de archivo;
      sin ventana activa → aviso de fallo; textos en español; fecha con printf (sin `date`). Probado en 12 casos con grim,
      slurp, notify-send, etc. falsos. shellcheck limpio.
- [x] 3.9 WallpaperEffects.sh (SUPER+SHIFT+U) rehecho. Antes: 17 efectos sobre el 4K (3–7 s cada uno), elegidos a ciegas, la mitad
      inservibles como fondo (Edge Detect negro, Charcoal/Negate blancos, marcos, elipses, recorte cuadrado), 4 s de sleeps y
      wallust en segundo plano. Ahora: 15 efectos elegidos por el usuario sobre una hoja de muestra (desenfoques, oscurecer,
      viñeta, duotono/tinte con la paleta de wallust del fondo original, desaturado, B/N, sepia, pixelado, ilustración), con
      miniatura en el menú. Se generan a la resolución del monitor, en paralelo, una vez por fondo (3,4 s con aviso; después
      17 ms) en `~/.cache/wallpaper-effects/` (solo el fondo actual, ~31 MB). Aplicar: inmediato + wallust síncrono antes de
      Refresh. «Sin efecto» vuelve al original a resolución completa. Efecto aplicado marcado al abrir. Efectos en una
      función con `case` (antes cadenas con `eval`). Rofi: `config-wallpaper-effect.rasi` en cuadrícula 5×3, ventana opaca
      (la transparencia del tema dejaba leer la terminal de detrás) y selección con texto negro (AA). Probado: capturas reales
      del menú, aplicar con awww/wallust falsos (3 efectos + cancelar). shellcheck limpio.
- [x] 3.10 Selector de tema de rofi unificado: RofiThemeSelector-modified.sh → legacy/ y SUPER+CTRL+SHIFT+R libre (decisión del
      usuario). RofiThemeSelector.sh (SUPER+CTRL+R, Ajustes rápidos): config.rasi siempre con UNA línea `@theme`, escrita con
      temporal + mv (antes cada vista previa añadía líneas y la «poda» dejaba restos: así salió repetida ×24); se restaura el
      tema anterior con Esc, si rofi muere o si matan el script (trap); textos en español; sin find/grep/basename.
      Probado con config.rasi de prueba y rofi falso (aplicar, cancelar, rofi muerto, script matado). 163 atajos.
- [x] 3.11 RofiEmoji.sh (SUPER+ALT+E) rehecho. Datos fuera del script: `scripts/emojis.txt` (1849 emojis, «categoría emoji
      nombre claves»; el script pasa de 89 KB a 4 KB). Cuadrícula 10×6 solo con el emoji (petición del usuario): nombre, claves
      y categoría en español van como «meta» invisible de rofi (se buscan igual). Categorías por grupos Unicode (los 111
      añadidos al final, clasificados a mano): Alt+1…9, Alt+0 = Todo con los 20 recientes delante
      (`~/.local/state/rofi-emoji/recientes`). Shift+Intro marca varios. Aviso «😀 copiado». Rofi: ventana opaca, fuente
      Noto Color Emoji 20 en el elemento + relleno 0.9em (si no, rofi corta los emojis), sin casilla de multi-select.
      Probado: lógica con rofi falso (categorías, recientes, varios, Esc) y capturas reales. Pendiente: claves en español
      (no hay datos CLDR en el sistema; habría que descargarlos).
- [x] 3.12 Cinco scripts cortos:
      AirplaneMode (XF86Rfkill): bloquea wifi Y Bluetooth (antes solo wifi) y al desactivar devuelve cada uno a como estaba
      (estado en $XDG_RUNTIME_DIR). El portátil no gestiona la tecla por hardware (rfkill sin dispositivo MSI).
      MediaCtrl (teclas multimedia): 1 llamada a playerctl en vez de 3–4, avisos que se sustituyen, títulos con & < > escapados,
      sleep 0.2 tras siguiente/anterior (si no, avisaba de la pista vieja). KillActiveProcess (SUPER+SHIFT+W): hyprctl -j,
      aviso con la clase cerrada, protege PID ≤ 1. Polkit: solo rutas de Arch, sin código inalcanzable tras exec, aviso si no
      hay agente. Hyprsunset (SUPER+M): avisos y tooltip en español.
      Corregido además escape() de Quick_Settings.sh (mismo fallo de bash 5.2: «<» salía como «<lt;»).
      Probado con rfkill/playerctl/hyprctl falsos, kill real sobre un sleep, agente falso; estado real de hyprsunset. shellcheck limpio.
- [x] 3.13 Repaso del resto. RofiBeats (SUPER+H): «Detener» mataba con kill -9 CUALQUIER mpv (también vídeos); ahora su mpv lleva
      `--title=RofiBeats` y solo se para ese (probado con otro mpv vivo). Quitar emisora quitaba también las que contenían el nombre
      («Lofi» → «Lofi Girl»); ahora nombre exacto. Menús y avisos en español, sin `ps aux | grep` de mpvpaper, «|» en el nombre
      no rompe la lista. Probado con mpv real reproduciendo silencio y rofi falso.
      `~/.local/bin/screenshot-ocr` (SUPER+S, fuera de git): grim → magick ×2 → tesseract en memoria (sin temporales en /tmp);
      ampliar al doble reconoce bastante más texto de pantalla (34 → 58 palabras en una prueba); aviso con salto de línea real,
      vista previa por caracteres (no corta tildes) y con & < > escapados. Probado con imágenes de texto conocido.
      Original: `tar -xzf ~/backup-scripts-2026-10-21.tar.gz -C ~ .local/bin/screenshot-ocr`.
      WaybarLayout/WaybarStyles: `pkill -x waybar`, sin un basename por estilo, textos en español; menús idénticos (md5).
      KeyBinds/KeyHints: `pkill -x yad`. Revisados sin cambios: ThemeChanger (los 5 destinos se generan, la espera acaba enseguida),
      WaybarScripts, Hypridle.sh, resto ya tocados en sesiones anteriores.
- [x] 3.14 Menú de RofiBeats (SUPER+H) rehecho: menú principal compacto (460 px) y opaco con iconos Nerd Font y una línea
      «▶ Sonando: …» (estado en $XDG_RUNTIME_DIR/rofibeats-now); «Detener» solo si suena algo; las opciones de música local
      solo aparecen si hay audio en ~/Music (ahora no hay ninguno: solo un proyecto). Emisoras: icono por tipo (FM/Radio/YT),
      nombre sin prefijo ni emojis finales y el tipo en pequeño; selección por número de fila. Gestión: añadir/quitar con
      iconos (quitado «Ver lista», era la misma lista). Rofi: config-rofi-Beats-menu.rasi (base) + config-rofi-Beats.rasi
      (listas, hereda y amplía). Probado: capturas reales y lógica con rofi/mpv falsos (fila → URL, quitar exacto, añadir con |).
- [x] Fase 5 (Rofi). Decisión del usuario: la transparencia de los menús y del lanzador se queda como está.
      9 temas con colores fijos (sin wallust) → ~/.config/rofi/legacy/themes (quedan 12). Los 28 .rasi cargan sin errores
      (rofi -dump-theme). config-wallpaper.rasi sin propiedades repetidas (tema resultante idéntico). Textos de ayuda de 9 menús
      en español; mensajes de RofiSearch, ThemeChanger, Kitty_themes y RofiCalc en español. RofiCalc: ayuda al abrir, resultado
      en el mensaje («2+2 = 4 · copiado») con escape, ejemplos de la ayuda comprobados con qalc («15% de 80» no lo entiende).
      Medido: abrir rofi con o sin imagen en la barra ≈ 25–30 ms → nada que optimizar.
- [x] RofiThemeSelector.sh → legacy/ y config-rofi-theme.rasi → rofi/legacy/ (petición del usuario): fuera SUPER+CTRL+R (libre)
      y la entrada «Tema de rofi» de Ajustes rápidos. El tema global queda fijo en style-8 (config.rasi). 162 atajos.
- [x] Calculadora (SUPER+C) mejorada sin instalar nada (el usuario descartó rofi-calc): qalc con coma decimal («3,5 * 2»,
      resultados «0,333…»); español → qalc: «15% de 80», «10 km a mi», «90 min en h» (y «to -X» para no dar «6 mi + 376 yd…»);
      el mensaje muestra el resultado en negrita, «Entendido como: …» (lo que interpretó qalc: así se ve que «hola» =
      hectobyte·liter·are) y avisos de qalc; historial de las 6 últimas (se guardan 50 en ~/.local/state/rofi-calc/historial).
      Intro siempre calcula (el historial va en el mensaje, no como filas: con filas, «2+2» habría elegido «2+2*3» del historial).
      config-calc.rasi: 560 px, franja fina, sin lista (antes «enable» mal escrito: no se ocultaba). Transparencia del tema intacta.
      Probado: 10 entradas con qalc real y rofi falso; capturas reales.
- [x] Calculadora con teclado (SUPER+C, petición del usuario): rofi en MODO SCRIPT (-modi calc:RofiCalc.sh): al pulsar una tecla
      rofi vuelve a llamar al script sin cerrar la ventana (no hay parpadeo; el estado viaja en ROFI_DATA). Teclado 5×5
      (C ⌫ ( ) ÷ / 7 8 9 % × / 4 5 6 √ − / 1 2 3 ^ + / 0 , π Ans =); pantalla arriba a la derecha con la operación grande y
      el resultado en vivo (qalc ≈ 33 ms; oculto si la operación está a medias, si no daba «= 0»). «=» calcula, copia,
      guarda historial; después un operador sigue con el resultado y cualquier otra cosa empieza de cero (también escribiendo).
      Se puede escribir (coma decimal, «15% de 80», «10 km a mi»; acabar en «=» calcula). Operadores en color de acento
      (filas «active»), «=» resaltado («urgent»). Mantiene la transparencia del tema. Probado: 20 pulsaciones simuladas con
      ROFI_RETV/ROFI_INFO/ROFI_DATA y qalc real; capturas reales. Trampa: «(» suelto en [[ =~ ]] o en case = error de sintaxis.
- [x] Fase 6: shellcheck, referencias de atajos/Waybar/hypridle/hyprlock, reload sin errores, rofi sin errores; INVENTARIO.md
      con el resultado final. Pendiente del usuario: desinstalar herramientas de la auditoría.
- [x] Borrados (petición del usuario): legacy/scripts/sddm_wallpaper.sh y waybar/legacy/contraste.py (recuperables con git).
      Emojis con claves en español: descartado por el usuario.
- [x] Selector de fondos (SUPER+U) y fondo del bloqueo (SUPER+CTRL+U): cuadrícula 8×4 = 32 fondos a la vista (antes 6×2 = 12),
      miniaturas cuadradas de 336 px en `~/.cache/wallpaper-thumbs` (19 MB; antes rofi decodificaba los originales, hasta 4K),
      generadas en paralelo una sola vez (≈23 s con aviso; después solo las nuevas o cambiadas). Código común en
      UserScripts/lib/wallthumbs.sh. Sin nombres visibles (se busca escribiendo); «Aleatorio»/«Escritorio» con la etiqueta
      pintada en la miniatura. Fondo al 96 % y franja de búsqueda fina. HyprlockBackground: los nombres con espacios se
      partían (`for name in $(…)`) → array. Trampa: magick interpreta «%» en el nombre de salida (%d, %o…) → separador «#».
      Probado: 807/807 miniaturas, 805 filas del bloqueo con miniatura, 7 filas → fondo exacto, capturas reales.
- [x] Selector de fondos: Intro = poner; Shift+Intro = PROBAR (solo la imagen en el monitor activo, fundido de 0,4 s, sin colores)
      y menú abajo «Quedarme con este» (aplica entero: wallust + Refresh) / «Probar otro» (restaura y vuelve a la cuadrícula en la
      misma fila) / «Volver al anterior» (= Esc: nunca se queda un fondo de prueba). Anterior leído con `awww query`.
      Shift+Intro era kb-accept-alt de rofi → movido a Alt+Intro. Vídeos: aviso (no se pueden probar).
      Nuevo config-wallpaper-confirm.rasi (hereda el menú compacto de RofiBeats, location south).
      Probado: 6 casos con rofi/awww/wallust falsos; captura del menú de confirmación.
- [ ] Experimentos «escritorio grande» 2D (2026-10-24, backup en ~/backups/hypr-2026-10-24_0953). Todo en experiments/,
      cada opción con su -uninstall.sh; atajos en la capa SUPER+CTRL+SHIFT (README.md). Carga ad-hoc con
      `hyprctl eval 'require("experiments.X")'`; `hyprctl reload` lo quita. hyprpm no viene en el paquete de Arch.
      a) scrolling nativo: probado y DESCARTADO por el usuario (no era un plano 2D); quitado, hyprland.lua idéntico al original.
      b) hyprplane: compila en 0.56.2 pero sin API Lua (solo addDispatcherV2) → inactivable; descartado y borrado por completo (2026-10-24).
      Phantomat (kaolti/phantomat @ a1e8a08) en lugar de b): compilado en experiments/build, cargado ad-hoc con
      phantomat-load.sh, ajustes del ejemplo SIN sus binds (reasignaban SUPER+T/G/L/P, ALT+TAB…). Probado: zoom 0.72↔1.0
      en ambos monitores. Al usuario le gustó, pero sustituye TODOS los workspaces por un plano → eliminado por completo.
      c) hyprscroll2d (@ f8d4edd, Lua puro): layout lua:hyprscroll2d solo en ws 10 vía hl.workspace_rule; atajos en capa
      SUPER+CTRL+SHIFT (elección del usuario). Probado: 3 ventanas en ws10 → lua:hyprscroll2d, ws5 sigue dwindle. Descartado por el usuario y eliminado.
      hyprplane + parche Lua propio (experiments/hyprplane-lua.patch): plano SOLO en ws 10. Probado: abrir/mover al 10,
      pan, apagar→mosaico, encender→posiciones recordadas, descarga con plano oculto limpia. Trampas: dlopen reutiliza
      la misma ruta (cargar desde ruta con hash + -fno-gnu-unique); hl.plugin.* aparece tras `hyprctl reload`; el
      PLUGIN_EXIT original encendía el plano en los ws visibles (zen/kitty del usuario quedaron flotando: recolocados,
      árbol dwindle reconstruido con master→dwindle, fullscreen de kitty restaurado). Al usuario le gustó pero quiere cambios → APARCADO (2026-10-24):
      desactivado y limpio, proyecto en experiments/hyprplane/ (CLAUDE.md, parche, setup/load/clean.sh); reproducible
      desde cero (binario idéntico). Primer paso al retomarlo: preguntar qué cambiar/arreglar.
- [x] 2026-10-27 hypridle: bloqueo 5 min, pantalla off 5,5, suspensión 15. Modo pensando (SUPER+ALT+C, scripts/ThinkingMode.sh):
      inhibidor systemd sleep+tapa; hypridle comprueba `systemd-inhibit --list` porque logind deja suspender al propio usuario.

- 2026-10-30: avisos con icono propio (juego, turbo, touchpad, modo avión, teclado, luz nocturna, emoji, polkit, distribución) y sin espacio inicial en el título. `WallustSwww.sh` regenera los iconos de notificación con la paleta nueva.
