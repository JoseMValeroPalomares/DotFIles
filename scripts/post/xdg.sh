#!/usr/bin/env bash
# XDG: crea las carpetas de usuario definidas en ~/.config/user-dirs.dirs

post_xdg() {
    local f="$HOME/.config/user-dirs.dirs" line dir
    [[ -f $f ]] || return 0
    while IFS= read -r line; do
        [[ $line =~ ^XDG_[A-Z]+_DIR=\"(.*)\"$ ]] || continue
        dir=${BASH_REMATCH[1]/\$HOME/$HOME}
        [[ -d $dir ]] || run mkdir -p "$dir"
    done <"$f"
    log_ok "Carpetas de usuario listas"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_xdg "$@"
fi
