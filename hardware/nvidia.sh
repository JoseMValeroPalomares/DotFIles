# shellcheck shell=bash
# Perfil NVIDIA: driver open DKMS (kernels linux y linux-zen), PRIME y, en gráficas
# híbridas (Intel + NVIDIA), envycontrol en modo hybrid con RTD3 (ahorro de batería).

hw_nvidia() {
    install_packages hw-nvidia

    local f=/etc/modprobe.d/nouveau.conf
    if [[ ! -f $f ]] || ! grep -qx 'blacklist nouveau' "$f"; then
        local tmp
        tmp=$(mktemp)
        echo 'blacklist nouveau' >"$tmp"
        install_system_file "$tmp" "$f" 644
        rm -f "$tmp"
    fi

    enable_service nvidia-persistenced.service

    if [[ " ${HARDWARE[*]} " == *" intel "* ]] && has envycontrol; then
        local mode
        mode=$(envycontrol --query 2>/dev/null || echo desconocido)
        if [[ $mode == hybrid ]]; then
            log_ok "envycontrol ya está en modo hybrid"
        elif confirm "Gráfica híbrida: ¿poner envycontrol en modo hybrid con RTD3 (regenera initramfs)?" s; then
            run_sudo envycontrol -s hybrid --rtd3 2
            mark ok "nvidia: envycontrol hybrid (reinicia para aplicarlo)"
        fi
    fi
}
