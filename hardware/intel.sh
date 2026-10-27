# shellcheck shell=bash
# Perfil Intel: microcódigo, aceleración de vídeo (VA-API) y KMS temprano (i915 en el initramfs)

has_intel_gpu() {
    local dev
    for dev in /sys/bus/pci/devices/*; do
        [[ $(<"$dev/vendor") == 0x8086 && $(<"$dev/class") == 0x03* ]] && return 0
    done
    return 1
}

hw_intel() {
    local had_ucode=0 conf=/etc/mkinitcpio.conf
    pkg_installed intel-ucode && had_ucode=1
    install_packages hw-intel

    if has_intel_gpu && [[ -f $conf ]] && ! grep -qE '^MODULES=\(.*\bi915\b' "$conf"; then
        log_info "Como en el portátil original: i915 en el initramfs (pantalla nítida desde el arranque)"
        if confirm "¿Añadir i915 a MODULES de mkinitcpio.conf y regenerar el initramfs?" s; then
            backup_system_file "$conf"
            run_sudo sed -i -E 's/^MODULES=\((.*)\)/MODULES=(\1 i915)/; s/^MODULES=\( /MODULES=(/' "$conf"
            run_sudo mkinitcpio -P
        fi
    fi
    if ((!had_ucode)); then
        log_info "intel-ucode es nuevo: regenera GRUB para cargarlo (sudo grub-mkconfig -o /boot/grub/grub.cfg)"
    fi
}
