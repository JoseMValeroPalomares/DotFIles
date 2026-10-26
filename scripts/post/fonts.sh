#!/usr/bin/env bash
# Fuentes: refresca la caché

post_fonts() {
    has fc-cache && run fc-cache -f >/dev/null
    log_ok "Caché de fuentes actualizada"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_fonts "$@"
fi
