#!/usr/bin/env bash
# Fondo aleatorio en el monitor activo (CTRL+ALT+W)

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# Transición de awww
AWWW_PARAMS=(--transition-fps 30 --transition-type random --transition-duration 1 --transition-bezier ".43,1.19,1,.4")

focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

mapfile -t PICS < <(find -L "$wallDIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o \
  -iname "*.pnm" -o -iname "*.tga" -o -iname "*.tiff" -o -iname "*.webp" -o -iname "*.bmp" -o \
  -iname "*.farbfeld" -o -iname "*.gif" \))
(( ${#PICS[@]} )) || exit 1
random_pic="${PICS[RANDOM % ${#PICS[@]}]}"

# Arrancar el daemon si no responde y esperar a que lo haga (máx. 2 s)
if ! awww query &>/dev/null; then
  awww-daemon --format xrgb &
  for _ in {1..20}; do awww query &>/dev/null && break; sleep 0.1; done
fi

awww img -o "$focused_monitor" "$random_pic" "${AWWW_PARAMS[@]}"

# WallustSwww.sh termina cuando las plantillas ya están escritas
"$SCRIPTSDIR/WallustSwww.sh" "$random_pic"
"$SCRIPTSDIR/Refresh.sh"
