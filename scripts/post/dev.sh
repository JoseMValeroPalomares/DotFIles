#!/usr/bin/env bash
# Desarrollo: Docker y grupos para puertos serie (Arduino/ESP32)

post_dev() {
    enable_service docker.service
    add_to_group docker
    add_to_group uucp
    add_to_group lock
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_dev "$@"
fi
