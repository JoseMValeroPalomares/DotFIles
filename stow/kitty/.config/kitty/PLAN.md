# Plan — Kitty (aspecto por foco, estética, rendimiento, usabilidad)

Diagnóstico: 2026-10-21

## Contexto verificado

- kitty 0.49.2 · Hyprland 0.56.2 (config **Lua**, `~/.config/hypr/hyprland.lua`) · wallust 3.5.2.
- Opacidad final = opacidad de Hyprland × `background_opacity` de Kitty (0.55).
- Regla vendor `configs/WindowRules.lua:176`: `tag terminal → opacity "0.9 0.7"` (sin 3.er valor → fullscreen 1.0).
- `UserConfigs/UserSettings.lua:110`: `tag = terminal` sin comillas → `nil` → la regla no aplica a nada.
- Blur global desactivado (`decoration.blur.enabled = false`).
- `kitty.conf` no incluye `kitty-themes/01-Wallust.conf`; la paleta de Wallust (dark16) es demasiado
  oscura para texto (color1–3 ≈ negro).
- Probado en vivo: con dos reglas para la misma ventana gana la **última**; `no_dim` existe.

## Decisiones del usuario (no reabrir)

- "Maximizada" = SUPER+F (pantalla completa, modo 2).
- Fuente: no se toca (familia ni tamaño).
- Blur: desactivado.
- Colores: probar el híbrido (paleta neón fija + acentos de Wallust); si no gusta, volver a los actuales.

## Fases

- [x] 0 Preparación: repo git, copia `kitty.conf.bak-2026-10-21`, PLAN/PROGRESS.
- [x] 1 Foco: regla en `~/.config/hypr/UserConfigs/WindowRules.lua` → `opacity "1.0 0.9 1.0"`, `no_dim`.
- [x] 2 Cristal: sin blur (decisión del usuario), sin cambios.
- [x] 3 Estética: acentos de Wallust (cursor, estela, pestañas, bordes, URL), barra de pestañas.
- [x] 4 Rendimiento: input/repaint delay, scrollback, shell_integration, remote control por socket.
- [x] 5 Usabilidad: splits/layouts, hints, scrollback pager, copy_on_select.
- [x] 6 Robustez: recarga de Kitty (SIGUSR1) al cambiar de fondo con Wallust.
