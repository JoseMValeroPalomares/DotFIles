#!/usr/bin/env bash
# Waybar: avisos de dependencias opcionales

post_waybar() {
    [[ -d $HOME/Projects/panel-maestro ]] ||
        log_warn "No está ~/Projects/panel-maestro: los módulos de agenda y captura rápida no harán nada"
    [[ -d $HOME/.config/hypr/scripts ]] ||
        log_warn "Sin el componente hyprland, varios módulos (volumen, wlogout, fondos) no funcionarán"
    return 0
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_waybar "$@"
fi
