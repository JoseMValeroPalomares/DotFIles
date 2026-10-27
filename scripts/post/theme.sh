#!/usr/bin/env bash
# Tema: aplica GTK, iconos, cursor y fuente con gsettings (lo que usa nwg-look)

THEME_GSETTINGS='
gtk-theme catppuccin-mocha-mauve-standard+default
icon-theme bessurf-dark-purple
cursor-theme catppuccin-mocha-lavender-cursors
cursor-size 24
font-name JetBrains Mono Bold 11
color-scheme prefer-dark
'

# Aplica la lista; se ejecuta dentro de un bus de sesión (real o temporal)
theme_apply_gsettings() {
    local k v rc=0
    while read -r k v; do
        [[ -z $k ]] && continue
        gsettings set org.gnome.desktop.interface "$k" "$v" || rc=1
    done <<<"$THEME_GSETTINGS"
    return "$rc"
}

post_theme() {
    if ! has gsettings; then
        log_warn "gsettings no disponible: el tema se aplicará al iniciar sesión vía settings.ini"
        return 0
    fi
    if ((DRY_RUN)); then
        log_info "gsettings: $(grep -c . <<<"$THEME_GSETTINGS") claves de org.gnome.desktop.interface"
        return 0
    fi
    if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
        theme_apply_gsettings || log_warn "Algún gsettings falló"
    elif has dbus-run-session; then
        # Instalación desde una TTY: no hay bus de sesión. Se crea uno temporal para que dconf
        # guarde los valores. Sin gvfs y con la salida cerrada: los servicios que active el bus
        # no deben quedarse con el terminal (colgaba las tuberías).
        GIO_USE_VFS=local THEME_GSETTINGS=$THEME_GSETTINGS \
            dbus-run-session -- bash -c "$(declare -f theme_apply_gsettings); theme_apply_gsettings" \
            </dev/null >/dev/null 2>&1 || log_warn "Algún gsettings falló"
    else
        log_warn "Sin D-Bus: el tema GTK se aplica igualmente por settings.ini"
        return 0
    fi
    log_ok "Tema aplicado"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_theme "$@"
fi
