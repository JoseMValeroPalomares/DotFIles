#!/usr/bin/env bash
# Overview (SUPER+A): Quickshell bajo demanda, AGS como respaldo

ipc() { qs ipc -c overview call overview "$1" >/dev/null 2>&1; }

if command -v qs >/dev/null 2>&1; then
  # Ya en marcha: mostrar/ocultar
  ipc toggle && exit 0

  # Primera vez en la sesión: arrancar una sola copia (-n) y abrir en cuanto responda (~150 ms)
  qs -n -d -c overview >/dev/null 2>&1
  for _ in $(seq 30); do
    ipc open && exit 0
    sleep 0.05
  done
fi

# Respaldo: AGS
if command -v ags >/dev/null 2>&1; then
  pkill -x rofi
  ags -t 'overview' >/dev/null 2>&1 && exit 0
  ags >/dev/null 2>&1 &
  sleep 0.6
  ags -t 'overview' >/dev/null 2>&1 && exit 0
fi

notify-send -i "$HOME/.config/swaync/images/error.png" "Overview" "No se pudo abrir Quickshell ni AGS" -u low 2>/dev/null
exit 1
