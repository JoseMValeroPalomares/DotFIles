#!/usr/bin/env bash
# Multimedia: PipeWire como servidor de audio del usuario

post_multimedia() {
    local u
    for u in pipewire.socket pipewire-pulse.socket wireplumber.service; do
        enable_service --user "$u"
    done
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_multimedia "$@"
fi
