# shellcheck shell=bash
# Perfil Intel: microcódigo y aceleración de vídeo (VA-API)

hw_intel() {
    local had_ucode=0
    pkg_installed intel-ucode && had_ucode=1
    install_packages hw-intel
    if ((!had_ucode)); then
        log_info "intel-ucode es nuevo: regenera GRUB para cargarlo (sudo grub-mkconfig -o /boot/grub/grub.cfg)"
    fi
}
