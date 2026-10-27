#!/usr/bin/env bash
# Termina el proceso de la ventana activa (SUPER+SHIFT+W), para programas que no responden a cerrar.
# Copied from Discord post. Thanks to @Zorg

iDIR="$HOME/.config/swaync/images"

read -r pid class < <(hyprctl -j activewindow | jq -r 'select(.pid) | "\(.pid) \(.class)"')

if [[ ! "$pid" =~ ^[0-9]+$ ]] || (( pid <= 1 )); then
    notify-send -u low -i "$iDIR/error.png" "Terminar proceso" "No hay ninguna ventana activa"
    exit 1
fi

if kill "$pid"; then
    notify-send -u low -i "$iDIR/ja.png" "Terminar proceso" "${class:-ventana} (PID $pid)"
else
    notify-send -u low -i "$iDIR/error.png" "Terminar proceso" "No se ha podido terminar ${class:-la ventana}"
    exit 1
fi
