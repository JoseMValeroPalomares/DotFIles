#!/usr/bin/env bash
# Bloqueo: hyprlock lee archivos de ~/.cache/hyprlock que generan sus scripts.
# Se crean vacíos si faltan para que hyprlock no falle la primera vez.

post_lock() {
    local c="$HOME/.cache/hyprlock" f
    run mkdir -p "$c"
    for f in colors.conf monitor.conf; do
        [[ -e $c/$f ]] || run touch "$c/$f"
    done
    log_info "Atajos: Ctrl+Alt+L bloquea · Super+L abre wlogout (con «Bloquear»)"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_lock "$@"
fi
