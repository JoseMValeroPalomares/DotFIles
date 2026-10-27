# Hyprland

![Hyprland](../../docs/capturas/hyprland.png)

Configuración de Hyprland en Lua (`hyprland.lua` carga `configs/` y después `UserConfigs/`, que manda).

## Qué incluye

- `configs/`: atajos (`Keybinds.lua`), reglas de ventana, variables, arranque, ajustes del portátil y modo juego.
- `UserConfigs/`: todo lo personalizado (atajos propios, decoración, animaciones, programas al iniciar).
- `scripts/` y `UserScripts/`: volumen, brillo, fondos con wallust, menús de rofi, overview, ajustes rápidos…
- `animations/`: presets que copia el menú de animaciones (Super+Shift+A).
- Semillas (`seeds/hyprland`): `monitors.lua`, `workspaces.lua` y los colores de wallust, que se reescriben solos.

## Atajos

- Super+D: lanzador (rofi)
- Super+A: overview (Quickshell)
- Super+L: menú de energía (wlogout)
- Ctrl+Alt+L: bloquear
- Super+H: chuleta de atajos
- Super+Shift+E: ajustes rápidos

## Instalar solo esto

```bash
./install.sh --only hyprland
```

Funciona mejor junto a: waybar, swaync, rofi, lock, wallust, kitty, filemanager. Sin ellos no falla nada, solo deja de responder lo que dependa de ellos.

[← Volver al README principal](../../README.md)
