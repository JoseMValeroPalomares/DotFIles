#!/usr/bin/env bash
# Tema: aplica GTK, iconos, cursor y fuente con gsettings (lo que usa nwg-look)

post_theme() {
    if ! has gsettings; then
        log_warn "gsettings no disponible: el tema se aplicará al iniciar sesión vía settings.ini"
        return 0
    fi
    # Desde una TTY (sistema recién instalado) no hay bus de sesión: dbus-run-session crea uno
    # temporal y dconf guarda los valores en ~/.config/dconf/user igualmente
    local -a wrap=()
    [[ -z ${DBUS_SESSION_BUS_ADDRESS:-} ]] && has dbus-run-session && wrap=(dbus-run-session --)
    local k v
    while read -r k v; do
        run "${wrap[@]}" gsettings set org.gnome.desktop.interface "$k" "$v" 2>/dev/null ||
            log_warn "gsettings $k falló"
    done <<'LIST'
gtk-theme catppuccin-mocha-mauve-standard+default
icon-theme bessurf-dark-purple
cursor-theme catppuccin-mocha-lavender-cursors
cursor-size 24
font-name JetBrains Mono Bold 11
color-scheme prefer-dark
LIST
    log_ok "Tema aplicado"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_theme "$@"
fi
