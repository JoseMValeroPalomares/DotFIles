#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Arranca el primer agente de Polkit instalado (ventana de contraseña para acciones de administrador)

agents=(
    /usr/lib/hyprpolkitagent/hyprpolkitagent              # el instalado (paquete hyprpolkitagent)
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
    /usr/lib/polkit-kde-authentication-agent-1
)

for agent in "${agents[@]}"; do
    [[ -x "$agent" && ! -d "$agent" ]] && exec "$agent"
done

notify-send -u critical "Polkit" "No hay ningún agente de Polkit instalado: las ventanas de contraseña no aparecerán"
exit 1
