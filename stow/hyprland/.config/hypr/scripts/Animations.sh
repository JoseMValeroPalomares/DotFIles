#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Menú de presets de animación (SUPER+SHIFT+A).
# Los presets son ~/.config/hypr/animations/*.lua; el elegido se guarda en
# UserConfigs/AnimationPreset y lo carga UserConfigs/UserAnimations.lua al recargar.

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill -x rofi
fi

# Variables
iDIR="$HOME/.config/swaync/images"
animations_dir="$HOME/.config/hypr/animations"
state_file="$HOME/.config/hypr/UserConfigs/AnimationPreset"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
default="macOS"
mark="● "

current=$(head -n1 "$state_file" 2>/dev/null)
current=${current:-$default}

# El modo juego apaga las animaciones y un reload lo desactivaría a medias
if [[ -e "${XDG_RUNTIME_DIR:-/tmp}/hypr-gamemode" ]]; then
  notify-send -u low -i "$iDIR/ja.png" "Animaciones" "Desactiva antes el modo juego (SUPER+ALT+G)"
  exit 0
fi

# macOS primero, el resto en orden natural; el activo marcado
animations_list=$(
  {
    echo "$default"
    find -L "$animations_dir" -maxdepth 1 -type f -name '*.lua' -printf '%f\n' \
      | sed 's/\.lua$//' | grep -vx "$default" | sort -V
  } | sed "s/^$(printf '%s' "$current" | sed 's/[][\.*^$/]/\\&/g')\$/$mark&/"
)

msg="Activo: $current  ·  Se aplica al momento y se recuerda"
chosen=$(echo "$animations_list" | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg")
chosen=${chosen#"$mark"}

[[ -z "$chosen" ]] && exit 0
if [[ ! -f "$animations_dir/$chosen.lua" ]]; then
  notify-send -u low -i "$iDIR/error.png" "Animaciones" "No existe el preset: $chosen"
  exit 1
fi

if [[ "$chosen" == "$default" ]]; then
  rm -f "$state_file"
else
  printf '%s\n' "$chosen" > "$state_file"
fi
hyprctl reload > /dev/null
notify-send -u low -i "$iDIR/ja.png" "$chosen" "Animaciones aplicadas"
