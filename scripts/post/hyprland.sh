#!/usr/bin/env bash
# Hyprland: carpetas de estado que los scripts esperan

post_hyprland() {
    run mkdir -p "$HOME/.config/hypr/wallpaper_effects" "$HOME/.cache"
    if [[ ! -f $HOME/.zprofile ]] || ! grep -q 'uwsm start' "$HOME/.zprofile" 2>/dev/null; then
        log_info "Hyprland se arranca desde .zprofile con uwsm en tty1 (componente zsh)"
    fi
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_hyprland "$@"
fi
