#!/usr/bin/env bash
# Canción de Spotify para hyprlock: una sola llamada a playerctl, con límite de tiempo.

MAX_LEN=35 # caracteres antes de cortar con «...»

if ! command -v playerctl &>/dev/null; then
  echo "Falta playerctl"
  exit 0
fi

# timeout: si D-Bus no responde, el label no se queda esperando
INFO=$(timeout 1 playerctl -p spotify metadata --format '{{status}}|{{title}} - {{artist}}' 2>/dev/null)
STATUS=${INFO%%|*}
INFO=${INFO#*|}

if [[ "$STATUS" == "Playing" || "$STATUS" == "Paused" ]]; then
  ((${#INFO} > MAX_LEN)) && INFO="${INFO:0:MAX_LEN}..."
  # hyprlock interpreta el texto como marcado Pango: & < > romperían el label
  INFO=${INFO//&/\&amp;}
  INFO=${INFO//</\&lt;}
  INFO=${INFO//>/\&gt;}
  echo "$INFO"
else
  echo "Nada en reproducción"
fi
