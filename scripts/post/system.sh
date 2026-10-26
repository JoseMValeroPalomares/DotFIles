#!/usr/bin/env bash
# Ajustes de sistema (/etc y /usr/local/bin). Todo con sudo, backup previo y confirmación.

SYSTEM_FILES="$DOTFILES/system/files"

# Activa una opción de pacman.conf si falta: pacman_opt "Color" | pacman_opt "ParallelDownloads" "10"
pacman_opt() {
    local key=$1 val=${2:-} line conf=/etc/pacman.conf
    line=$key
    [[ -n $val ]] && line="$key = $val"
    if grep -qxE "$key( *= *$val)?" "$conf"; then
        return 0
    fi
    backup_system_file "$conf"
    if grep -qE "^#? *$key\b" "$conf"; then
        run_sudo sed -i -E "s|^#? *$key\b.*|$line|" "$conf"
    else
        run_sudo sed -i "/^\[options\]/a $line" "$conf"
    fi
}

post_system() {
    log_warn "Este componente modifica archivos de /etc (con copia previa en el backup)."
    confirm "¿Aplicar los ajustes de sistema (zram, sysctl, reflector, pacman, Wi-Fi ES)?" s || {
        mark skip "system: cancelado por el usuario"
        return 0
    }

    local f
    while IFS= read -r -d '' f; do
        local dest=${f#"$SYSTEM_FILES"}
        if [[ $dest == /usr/local/bin/* ]]; then
            install_system_file "$f" "$dest" 755
        else
            install_system_file "$f" "$dest" 644
        fi
    done < <(find "$SYSTEM_FILES" -type f -print0)

    pacman_opt Color
    pacman_opt ILoveCandy
    pacman_opt ParallelDownloads 10

    local regdom=/etc/conf.d/wireless-regdom
    if [[ -f $regdom ]] && ! grep -q '^WIRELESS_REGDOM="ES"' "$regdom"; then
        backup_system_file "$regdom"
        run_sudo sed -i 's/^#WIRELESS_REGDOM="ES"/WIRELESS_REGDOM="ES"/' "$regdom"
    fi

    run_sudo sysctl --system >/dev/null
    run_sudo systemctl daemon-reload

    local u
    for u in earlyoom.service irqbalance.service systemd-timesyncd.service lm_sensors.service \
             paccache.timer fstrim.timer reflector.timer plocate-updatedb.timer; do
        enable_service "$u"
    done
    log_info "zram se activa en el próximo arranque (o: sudo systemctl restart systemd-zram-setup@zram0)"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_system "$@"
fi
