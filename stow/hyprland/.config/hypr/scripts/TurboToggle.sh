#!/usr/bin/env bash
# Activa/desactiva el Turbo Boost de Intel (SUPER+T)
# Escribir en no_turbo requiere root: usa sudo sin contraseña si existe la regla
# (ver /etc/sudoers.d/turbo-toggle) y si no, pkexec (pide contraseña).

notif="$HOME/.config/swaync/icons/turbo.png"
no_turbo="/sys/devices/system/cpu/intel_pstate/no_turbo"

if [[ ! -r "$no_turbo" ]]; then
    notify-send -u normal -i "$notif" "Turbo" "No se encuentra $no_turbo (¿intel_pstate desactivado?)"
    exit 1
fi

# no_turbo=1 significa turbo desactivado
if [[ "$(<"$no_turbo")" == "1" ]]; then
    new=0 msg="activado"
else
    new=1 msg="desactivado"
fi

if echo "$new" | sudo -n /usr/bin/tee "$no_turbo" >/dev/null 2>&1 ||
    echo "$new" | pkexec /usr/bin/tee "$no_turbo" >/dev/null; then
    notify-send -u low -i "$notif" "Turbo" "Modo turbo $msg"
else
    notify-send -u normal -i "$notif" "Turbo" "No se pudo cambiar el modo turbo"
    exit 1
fi
