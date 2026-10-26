#!/usr/bin/env bash
# Base: servicios del sistema esenciales

post_base() {
    enable_service NetworkManager.service
    add_to_group input
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_base "$@"
fi
