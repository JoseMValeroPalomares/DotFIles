#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# For Hyprlock
#pidof hyprlock || hyprlock -q

# Bloquear primero; el tiempo (Waybar/hyprlock) se refresca después en segundo plano
loginctl lock-session

setsid -f "$HOME/.config/waybar/scripts/clima.py" --forzar >/dev/null 2>&1
