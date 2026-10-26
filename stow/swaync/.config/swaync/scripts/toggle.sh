#!/usr/bin/env bash
# Toggles del grid de swaync.
#   toggle.sh <wifi|bt|mute|mic> get  -> imprime true/false
#   toggle.sh <wifi|bt|mute|mic> set  -> aplica $SWAYNC_TOGGLE_STATE
what=$1 op=$2
on=false; [ "$SWAYNC_TOGGLE_STATE" = true ] && on=true

case "$what:$op" in
  wifi:get) [ "$(nmcli radio wifi)" = enabled ] && echo true || echo false ;;
  wifi:set) $on && nmcli radio wifi on || nmcli radio wifi off ;;
  bt:get)   bluetoothctl show | grep -q 'Powered: yes' && echo true || echo false ;;
  bt:set)   $on && bluetoothctl power on >/dev/null || bluetoothctl power off >/dev/null ;;
  mute:get) pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && echo true || echo false ;;
  mute:set) $on && pactl set-sink-mute @DEFAULT_SINK@ 1 || pactl set-sink-mute @DEFAULT_SINK@ 0 ;;
  mic:get)  pactl get-source-mute @DEFAULT_SOURCE@ | grep -q yes && echo true || echo false ;;
  mic:set)  $on && pactl set-source-mute @DEFAULT_SOURCE@ 1 || pactl set-source-mute @DEFAULT_SOURCE@ 0 ;;
  *) echo "uso: $0 <wifi|bt|mute|mic> <get|set>" >&2; exit 1 ;;
esac
