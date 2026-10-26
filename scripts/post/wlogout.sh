#!/usr/bin/env bash
# wlogout: compila la versión parcheada (flechas) en ~/.config/wlogout/bin/wlogout.
# Si falla, Wlogout.sh usa el wlogout del sistema (paquete AUR).

post_wlogout() {
    local bin="$HOME/.config/wlogout/bin/wlogout" build="$HOME/.config/wlogout/src/build.sh"
    if [[ -x $bin ]]; then
        log_ok "wlogout parcheado ya compilado"
        return 0
    fi
    if [[ ! -f $build ]] && ! ((DRY_RUN)); then
        log_warn "No encuentro $build"
        return 0
    fi
    log_info "Compilando wlogout 1.2.2 con wlogout-flechas.patch"
    run bash "$build" || {
        log_warn "La compilación falló: se usará el wlogout del sistema"
        mark err "wlogout: compilación del parche"
    }
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_wlogout "$@"
fi
