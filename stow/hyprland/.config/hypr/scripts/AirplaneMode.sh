#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modo avión (tecla XF86Rfkill): bloquea wifi y Bluetooth con rfkill.
# Al desactivarlo, cada uno vuelve a como estaba (si el Bluetooth estaba apagado, sigue apagado).

notif="$HOME/.config/swaync/images/ja.png"
state="${XDG_RUNTIME_DIR:-/tmp}/airplane-mode"   # tipos que estaban activos antes de activarlo

notify() { notify-send -e -u low -h string:x-canonical-private-synchronous:airplane -i "$notif" "Modo avión" "$1"; }

# ¿Está desbloqueado (por software) algún dispositivo de este tipo?
is_on() { rfkill list "$1" | grep -q 'Soft blocked: no'; }

if [[ -f "$state" ]]; then
    # Desactivar: devolver los que estaban encendidos
    while read -r type; do
        rfkill unblock "$type"
    done < "$state"
    rm -f "$state"
    notify "Desactivado"
else
    # Activar: recordar qué estaba encendido y bloquearlo todo
    : > "$state"
    for type in wifi bluetooth; do
        is_on "$type" && echo "$type" >> "$state"
    done
    rfkill block wifi
    rfkill block bluetooth
    notify "Activado: wifi y Bluetooth apagados"
fi
