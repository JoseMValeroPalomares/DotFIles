#!/usr/bin/env bash
# «Modo pensando» (SUPER+ALT+C): mientras está activo el portátil no se suspende
# (ni por inactividad ni al cerrar la tapa), para que
# Claude Code pueda seguir trabajando. La pantalla sí se bloquea y se apaga como siempre.
# Funciona con un inhibidor de systemd; al volver a pulsar se quita y todo vuelve a lo normal.
# Comprobar a mano: systemd-inhibit --list

notif="$HOME/.config/swaync/images/ja.png"
icon_on="$HOME/.claude/icons/claude-code.png"
icon_off="$HOME/.claude/icons/claude-code-off.png"
tag="modo-pensando"

pids=$(pgrep -f "systemd-inhibit --who=$tag")

if [[ -n "$pids" ]]; then
    kill $pids
    notify-send -u low -i "$icon_off" "Modo pensando" "Desactivado: vuelve la suspensión a los 15 min"
else
    setsid -f systemd-inhibit --who="$tag" --what=sleep:handle-lid-switch \
        --why="Claude Code trabajando" --mode=block sleep infinity >/dev/null 2>&1
    sleep 0.3
    if pgrep -f "systemd-inhibit --who=$tag" >/dev/null; then
        notify-send -u low -i "$icon_on" "Modo pensando" "Activado: el portátil no se suspenderá"
    else
        notify-send -u normal -i "$notif" "Modo pensando" "No se pudo activar el inhibidor"
        exit 1
    fi
fi
