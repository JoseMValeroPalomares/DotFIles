#!/usr/bin/env bash
# Nano: resaltado de sintaxis de scopatz/nanorc en ~/.nano (lo incluye ~/.config/nano/nanorc)

post_nano() {
    git_clone_once https://github.com/scopatz/nanorc.git "$HOME/.nano"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_nano "$@"
fi
