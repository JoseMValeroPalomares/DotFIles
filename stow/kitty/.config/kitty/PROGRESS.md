# Progreso — Kitty

## 2026-10-21

- [x] F0 Repo git en `~/.config/kitty`, copia `kitty.conf.bak-2026-10-21`, `.gitignore`
      (ignora `01-Wallust.conf`, generado), PLAN.md y PROGRESS.md.
- [x] F1 Regla `kitty-focus-look` en `~/.config/hypr/UserConfigs/WindowRules.lua`:
      `opacity "1.0 0.9 1.0"` (foco / sin foco / pantalla completa) y `no_dim`.
      Probado antes en una ventana `hyprtest`: la última regla gana sobre la vendor `0.9 0.7`.
      Pendiente: prueba visual del usuario.
- [x] Bug dropterm (hypr `configs/Keybinds.lua`): si se movía a un escritorio normal, SUPER+SHIFT+Return
      hacía toggle de special:dropterm vacío → no aparecía ni desaparecía. Ahora la devuelve al especial
      y la muestra (move sin silent). Probado con ventana hyprtest: recupera → oculta → muestra.
- [x] Dropterm v2: si se mueve a otro escritorio/monitor, la tecla la esconde y la vuelve a sacar allí
      (sitio en `$XDG_RUNTIME_DIR/hypr-dropterm-home`, sobrevive a reload; se olvida al abrir una nueva).
      API 0.56: `window.move{ follow = false }` = silent; el sufijo " silent" NO vale (crea un especial con ese nombre).
      Probado: abre → oculta → muestra → mover a ws 2 → oculta → reaparece en 2 → oculta → reload → reaparece.
- [x] Auditoría de actualizaciones de la base original: no queda ningún mecanismo activo (ver resumen en la sesión).
- [x] Limpieza Waybar (commit 67c70d2 en ~/.config/waybar): fuera `custom/dot_update` (definición, grupo
      `group/notify` y selectores en 55 estilos). `custom/updater` se queda: es del sistema, no de la base original.
- [x] F3 Colores híbridos: plantilla `~/.config/wallust/templates/colors-kitty-accents.conf` → `wallust-accents.conf`
      (cursor/pestaña activa = color15, estela/URL/borde split = color14; inactivos neutros). Registrada en
      wallust.toml (copia `wallust.toml.bak-2026-10-21-kitty`). Fondo, texto y paleta ANSI siguen fijos.
      Barra de pestañas powerline slanted (≥2 pestañas). Estela: cursor_trail 3, start_threshold 3.
      Validado con load_config de kitty (sin avisos); contraste del texto ≥ 6:1. Recarga en vivo con SIGUSR1.
      Revertir colores: comentar `include wallust-accents.conf`. Pendiente: prueba visual del usuario.
- [x] F4a Latencia: `repaint_delay 6` (144 Hz = 6.9 ms/fotograma; con 10 se quedaba en ~100 fps), `input_delay 2`.
      `update_check_interval` ya es 0 en el paquete de Arch (sin red). Truecolor en tmux OK (`RGB` en client_termfeatures).
- [x] F4b tmux (decisión del usuario: mantenerlo): cada kitty/pestaña crea sesión (ZSH_TMUX_AUTOCONNECT=false) y al
      cerrar quedaba huérfana: había 38 (3 en uso, ~444 MB). `set -g destroy-unattached on` en ~/.tmux.conf
      (copia ~/.tmux.conf.bak-2026-10-21). Probado: la sesión de una kitty de prueba desaparece al cerrarla.
      Cerradas 32 sesiones con zsh ocioso en ~.
      INCIDENTE: se destruyeron también 0 (Claude Code desacoplado en ~/.config), 2 y 4, que el usuario quería
      conservar. Causas: (1) `set -t "=0"` no vale en set-option ("No such session") y no se comprobó antes de
      recargar; (2) en zsh la variable `path` está ligada a PATH: usarla en el bucle rompió pgrep y la comprobación
      de procesos hijo no se hizo. Daño: el claude de la sesión 0 (conversación guardada, reanudable con
      `claude --resume b371e10f-fc46-44e9-9a3e-735ef8badd4f` en ~/.config); 2 y 4 eran zsh en el prompt.
- [x] F5 Usabilidad (con tmux como gestor de pestañas/splits/scroll):
      - Fuera el bloque de barra de pestañas y los colores de pestaña de la plantilla (apenas se usan pestañas;
        cada una abría un tmux). copy_on_select yes se mantiene (el usuario tiene historial cliphist).
      - Hints documentados en kitty.conf; Ctrl+Shift+P > N abre archivo:línea en VS Code (`code --goto`).
        Límite: rutas relativas se resuelven desde el cwd de tmux (~), no del panel.
      - tmux `history-limit 3000` (paneles nuevos).
      - Portapapeles SUPER+V (rofi `config-clipboard.rasi`, copia .bak-2026-10-21): 960×828 → 720×520,
        JetBrains Mono Medium 11 (antes Noto Sans Mono 12), banner fino, fondo casi opaco, sin IDs de cliphist
        (`-display-columns 2`), ayuda en español, seleccionado negro sobre color15 (10.7:1; antes 3.9:1).
      - Bug ClipManager.sh: rofi matado por señal (código 143) → el bucle lo relanzaba; ahora `*) exit`.
- [x] F5 revisada (al usuario no le gustaron los hints ni crear ventanas: cambiaban colores/fuente): fuera el mapeo
      a VS Code y la documentación; `no_op` en Ctrl+Shift+E, Ctrl+Shift+P > F/Shift+F/H/L/N/W/Y/C/D, Ctrl+Shift+T,
      Ctrl+Shift+Enter y Ctrl+Shift+L. En el keymap el no_op queda como última definición (la que vale).
      El aspecto de la kitty recién abierta es la referencia: no tocarlo.
- [x] F6 Robustez: `WallustSwww.sh` (selector, aleatorio, automático) espera a `wallust-accents.conf` y manda
      SIGUSR1 a kitty; `Refresh.sh` (efectos) también. Bug previo arreglado: sin argumentos, WallustSwww leía la
      caché de swww (abril, formato `filtro\0ruta`) y la consulta usaba el formato viejo → WallpaperRandom y
      RefreshNoWaybar nunca actualizaban colores. Ahora manda `swww query` (0.12). Probado con el fondo actual:
      wallust corre, acentos regenerados, kitty avisadas. (Ojo: en el Bash de Claude HYPRLAND_INSTANCE_SIGNATURE
      apunta a una instancia muerta; exportar la buena para probar.)
