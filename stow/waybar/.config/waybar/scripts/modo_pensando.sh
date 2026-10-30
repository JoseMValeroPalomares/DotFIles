#!/usr/bin/env bash
# Estado del «modo pensando» (SUPER+ALT+C) para el módulo custom/modo-pensando de Waybar.
# Solo lee: quien lo activa y lo quita es ~/.config/hypr/scripts/ThinkingMode.sh.
# El patrón va anclado para no confundir el inhibidor con un comando que simplemente cite ese texto.

if pgrep -f '^systemd-inhibit --who=modo-pensando' >/dev/null; then
    estado=activo
    aviso="Modo pensando activo: el portátil no se suspende"
else
    estado=normal
    aviso="Suspensión normal: a los 15 min de inactividad"
fi

printf '{"text": "%s", "alt": "%s", "class": "%s", "tooltip": "%s\\nClic o SUPER+ALT+C: cambiar"}\n' \
    "$estado" "$estado" "$estado" "$aviso"
