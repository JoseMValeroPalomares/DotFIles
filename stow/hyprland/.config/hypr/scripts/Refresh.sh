#!/usr/bin/env bash
# Recarga la barra y los menús tras cambiar fondo, tema o diseño de Waybar (también SUPER+ALT+R)

# Menús abiertos: rofi y el overview de Quickshell (se vuelve a abrir solo con SUPER+A)
pkill -x rofi
pkill -x qs

# Waybar: reiniciar (recoge colores, estilo y diseño nuevos). Esperar a que se cierre
# para no acabar con dos barras; setsid la separa de quien llama a este script.
if pkill -x waybar; then
  for _ in {1..20}; do pgrep -x waybar >/dev/null || break; sleep 0.05; done
fi
setsid -f waybar >/dev/null 2>&1

# swaync: solo recargar estilo y config (lo gestiona systemd; matarlo borraba el historial)
swaync-client --reload-css >/dev/null 2>&1
swaync-client --reload-config >/dev/null 2>&1

# kitty: SIGUSR1 recarga su config (acentos de Wallust); WallpaperEffects.sh depende de esto
pkill -USR1 -x kitty

exit 0
