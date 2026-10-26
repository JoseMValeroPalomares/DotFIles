#!/usr/bin/env bash
# Batería y tiempo encendido para hyprlock, en una línea y en español.
# Solo builtins de bash (sin procesos externos): hyprlock lo ejecuta a menudo.

parts=()

for bat in /sys/class/power_supply/BAT*; do
  [[ -r "$bat/capacity" ]] || continue
  read -r cap <"$bat/capacity"
  read -r status <"$bat/status"
  case "$status" in
  Charging) icon=$'\U000f0084' ;;       # 󰂄
  "Not charging" | Full) icon=$'\U000f06a5' ;; # 󰚥 enchufado (límite de carga del portátil)
  *)
    # 󰁺 … 󰂂 según el nivel, 󰁹 lleno
    levels=($'\U000f007a' $'\U000f007b' $'\U000f007c' $'\U000f007d' $'\U000f007e'
      $'\U000f007f' $'\U000f0080' $'\U000f0081' $'\U000f0082' $'\U000f0079')
    i=$((cap / 10))
    ((i > 9)) && i=9
    icon=${levels[i]}
    ;;
  esac
  parts+=("$icon $cap %")
done

read -r up _ </proc/uptime
s=${up%.*}
d=$((s / 86400)) h=$((s % 86400 / 3600)) m=$((s % 3600 / 60))
if ((d > 0)); then
  parts+=($'\U000f051f'" $d d $h h")
elif ((h > 0)); then
  parts+=($'\U000f051f'" $h h $m min")
else
  parts+=($'\U000f051f'" $m min")
fi

sep="   ·   "
out="${parts[0]}"
for p in "${parts[@]:1}"; do out+="$sep$p"; done
echo "$out"
