# shellcheck shell=bash
# Perfil Bluetooth

hw_bluetooth() {
    install_packages hw-bluetooth
    enable_service bluetooth.service
}
