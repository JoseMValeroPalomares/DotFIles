#!/usr/bin/env bash
# Wallpapers: no van en el repo. Se crea la carpeta que usan los scripts de fondos.

post_wallpapers() {
    local pics dir
    pics=$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")
    dir="$pics/wallpapers"
    run mkdir -p "$dir"
    if [[ -z $(ls -A "$dir" 2>/dev/null) ]]; then
        log_warn "La carpeta ${dir/#$HOME/\~} está vacía: copia ahí tus fondos desde tu drive"
        mark skip "wallpapers: carpeta vacía, copia los fondos a mano"
    else
        log_ok "Wallpapers: $(find "$dir" -type f | wc -l) archivos en ${dir/#$HOME/\~}"
    fi
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_wallpapers "$@"
fi
