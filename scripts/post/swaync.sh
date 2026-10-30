#!/usr/bin/env bash
# SwayNC: iconos con los colores de wallust, avisos del sistema y sin duplicados de otras apps

post_swaync() {
    run "$HOME/.config/swaync/scripts/gen-icons.py" --force
    # notifyd avisa de red y Bluetooth con el mismo estilo que el resto: se apagan los avisos propios
    run gsettings set org.gnome.nm-applet disable-connected-notifications true &&
        run gsettings set org.gnome.nm-applet disable-disconnected-notifications true &&
        run gsettings set org.blueman.general plugin-list "['!ConnectionNotifier']" ||
        log_warn "Sin nm-applet, blueman o sesión gráfica: sus avisos propios siguen activos"

    if ! ((DRY_RUN)) && ! systemctl --user show-environment >/dev/null 2>&1; then
        log_warn "No hay gestor de usuario de systemd: ejecuta ./install.sh --only swaync tras iniciar sesión"
        mark skip "swaync: notifyd sin activar"
        return 0
    fi
    run systemctl --user daemon-reload
    enable_service --user notifyd.service
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_swaync "$@"
fi
