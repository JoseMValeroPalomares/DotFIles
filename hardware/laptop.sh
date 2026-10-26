# shellcheck shell=bash
# Perfil portátil: perfiles de energía y control térmico

hw_laptop() {
    install_packages hw-laptop
    if systemctl is-enabled --quiet auto-cpufreq.service 2>/dev/null || systemctl is-enabled --quiet tlp.service 2>/dev/null; then
        log_warn "Tienes auto-cpufreq o TLP activos: chocan con power-profiles-daemon; desactívalos tú"
    fi
    enable_service power-profiles-daemon.service
    enable_service thermald.service
}
