#!/usr/bin/env bash
# Activa/desactiva el touchpad (tecla xf86TouchpadToggle)
# El dispositivo se detecta solo con `hyprctl devices`; se puede forzar con TOUCHPAD_DEVICE=nombre
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

set -euo pipefail

notif="$HOME/.config/swaync/images/ja.png"
status_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.status"

touchpad_device="${TOUCHPAD_DEVICE:-$(hyprctl -j devices | jq -r '[.mice[].name | select(test("touchpad"; "i"))][0] // empty')}"

if [[ -z "$touchpad_device" ]]; then
    notify-send -u low -i "$notif" " Touchpad" " No se ha encontrado ningún touchpad"
    exit 1
fi

set_touchpad() {
    hyprctl eval "hl.device({ name = \"$touchpad_device\", enabled = $1 })" >/dev/null
    printf '%s' "$1" >"$status_file"
}

# Sin archivo de estado, el touchpad está activo (así arranca la sesión)
current_state="true"
[[ -f "$status_file" ]] && current_state="$(<"$status_file")"

if [[ "$current_state" == "true" ]]; then
    set_touchpad false
    notify-send -u low -i "$notif" " Touchpad" " Desactivado"
else
    set_touchpad true
    notify-send -u low -i "$notif" " Touchpad" " Activado"
fi
