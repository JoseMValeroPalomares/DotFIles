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

# Idioma, teclado y zona horaria como en el portátil original
SYS_LOCALES=(en_US.UTF-8 es_ES.UTF-8)
SYS_LANG=en_US.UTF-8
SYS_KEYMAP=us
SYS_TIMEZONE=Europe/Madrid

system_locale() {
    local l changed=0 gen=/etc/locale.gen
    for l in "${SYS_LOCALES[@]}"; do
        if ! grep -qE "^${l//./\\.} UTF-8" "$gen"; then
            ((changed)) || backup_system_file "$gen"
            run_sudo sed -i -E "s/^# *(${l//./\\.} UTF-8)/\1/" "$gen"
            changed=1
        fi
    done
    ((changed)) && run_sudo locale-gen
    if ! grep -qx "LANG=$SYS_LANG" /etc/locale.conf 2>/dev/null; then
        backup_system_file /etc/locale.conf
        run_sudo sh -c "echo LANG=$SYS_LANG > /etc/locale.conf"
    fi
    if ! grep -qx "KEYMAP=$SYS_KEYMAP" /etc/vconsole.conf 2>/dev/null; then
        backup_system_file /etc/vconsole.conf
        run_sudo sh -c "echo KEYMAP=$SYS_KEYMAP >> /etc/vconsole.conf"
    fi
    if [[ $(readlink -f /etc/localtime) != "/usr/share/zoneinfo/$SYS_TIMEZONE" ]]; then
        run_sudo ln -sf "/usr/share/zoneinfo/$SYS_TIMEZONE" /etc/localtime
    fi
    log_ok "Idioma $SYS_LANG (+ es_ES), teclado $SYS_KEYMAP, zona $SYS_TIMEZONE"
}

# Autologin en tty1: .zprofile arranca Hyprland con uwsm en tty1, así que se entra directo
system_autologin() {
    local dest=/etc/systemd/system/getty@tty1.service.d/autologin.conf tmp
    tmp=$(mktemp)
    sed "s/@USER@/$USER/" "$DOTFILES/system/templates/autologin.conf" >"$tmp"
    if cmp -s "$tmp" "$dest"; then
        log_ok "Autologin en tty1 ya configurado"
    elif confirm "¿Activar el inicio de sesión automático de $USER en tty1 (arranca Hyprland solo)?" s; then
        install_system_file "$tmp" "$dest" 644
    fi
    rm -f "$tmp"
}

post_system() {
    log_warn "Este componente modifica archivos de /etc (con copia previa en el backup)."
    confirm "¿Aplicar los ajustes de sistema (pacman, zram, sysctl, reflector, idioma, autologin, Wi-Fi ES)?" s || {
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

    system_locale
    system_autologin

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
