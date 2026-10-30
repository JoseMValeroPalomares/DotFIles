#!/usr/bin/env bash
# Modo juego / ahorro de energía (SUPER+ALT+G o Quick Settings)
# - Sin modo activo: menú para elegir modo y frecuencia (60/144 Hz)
# - Con modo activo: lo desactiva y restaura tus ajustes y perfil de energía
# Los ajustes de Hyprland los guarda/restaura configs/GameMode.lua (sin hyprctl reload)

notif="$HOME/.config/swaync/icons/game.png"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
state_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-gamemode" # contiene: modo hz perfil_anterior

restore_profile() {
    [[ -f "$state_file" ]] || return 0
    local _mode _hz prev
    read -r _mode _hz prev <"$state_file"
    if [[ -n "$prev" ]] && command -v powerprofilesctl >/dev/null; then
        powerprofilesctl set "$prev"
    fi
    rm -f "$state_file"
}

# Llamado por GameMode.lua cuando Hyprland recarga la config con un modo activo
if [[ "$1" == "--restore-profile" ]]; then
    restore_profile
    notify-send -e -u low -i "$notif" "Modo normal" "Config recargada: ajustes restaurados"
    exit 0
fi

# Hay un modo activo: desactivar
if [[ -f "$state_file" ]]; then
    hyprctl eval 'require("configs.GameMode").disable()' >/dev/null
    restore_profile
    notify-send -e -u low -i "$notif" "Modo normal" "Ajustes restaurados"
    exit 0
fi

# Mismo comportamiento que los demás menús: si rofi está abierto, se cierra
if pidof rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

choice=$(printf '%s\n' \
    "🎮  Juego · 144 Hz" \
    "🎮  Juego · 60 Hz" \
    "🔋  Ahorro de energía · 60 Hz" \
    "🔋  Ahorro de energía · 144 Hz" |
    rofi -i -dmenu -config "$rofi_theme" -mesg "Modo de rendimiento")

case "$choice" in
    *"Juego · 144"*)  mode=game;  hz=144; profile=performance ;;
    *"Juego · 60"*)   mode=game;  hz=60;  profile=performance ;;
    *"Ahorro"*"60"*)  mode=saver; hz=60;  profile=power-saver ;;
    *"Ahorro"*"144"*) mode=saver; hz=144; profile=power-saver ;;
    *) exit 0 ;;
esac

prev=""
command -v powerprofilesctl >/dev/null && prev=$(powerprofilesctl get 2>/dev/null)
echo "$mode $hz $prev" >"$state_file"

if [[ "$(hyprctl eval "require(\"configs.GameMode\").enable(\"$mode\", $hz)" 2>&1)" != "ok" ]]; then
    rm -f "$state_file"
    notify-send -e -u critical -i "$notif" "Modo rendimiento" "No se pudo activar (ver hyprctl rollinglog)"
    exit 1
fi

[[ -n "$prev" ]] && powerprofilesctl set "$profile"

if [[ "$mode" == "game" ]]; then
    notify-send -e -u low -i "$notif" "Modo juego" "${hz} Hz · perfil ${profile}"
else
    notify-send -e -u low -i "$notif" "Ahorro de energía" "${hz} Hz · perfil ${profile}"
fi
