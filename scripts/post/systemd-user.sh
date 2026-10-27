#!/usr/bin/env bash
# Servicios de usuario: solo se activan si existe su proyecto (WorkingDirectory)

post_systemd_user() {
    local unit wd name
    if ! ((DRY_RUN)) && ! systemctl --user show-environment >/dev/null 2>&1; then
        log_warn "No hay gestor de usuario de systemd (¿chroot o contenedor?): vuelve a ejecutar este paso tras iniciar sesión"
        mark skip "systemd-user: sin sesión de usuario, ejecuta ./install.sh --only systemd-user"
        return 0
    fi
    run systemctl --user daemon-reload
    for unit in "$DOTFILES"/stow/systemd-user/.config/systemd/user/*.service; do
        [[ -f $unit ]] || continue
        name=$(basename "$unit")
        wd=$(sed -n 's/^WorkingDirectory=//p' "$unit")
        if [[ -n $wd && ! -d $wd ]]; then
            log_warn "$name: falta $wd, no se activa"
            mark skip "systemd-user: $name (falta su proyecto)"
            continue
        fi
        enable_service --user "$name"
    done
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_systemd_user "$@"
fi
