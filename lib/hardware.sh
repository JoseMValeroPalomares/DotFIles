# shellcheck shell=bash
# Autodetección de hardware (sin dependencias: lee /sys)

# shellcheck disable=SC2034  # HW_PROFILES y HW_DESC se usan en install.sh
HW_PROFILES=(intel amd nvidia laptop bluetooth msi)
# shellcheck disable=SC2034
declare -A HW_DESC=(
    [intel]="GPU/CPU Intel: microcódigo y VA-API"
    [amd]="GPU/CPU AMD: microcódigo, mesa y Vulkan"
    [nvidia]="NVIDIA: driver open DKMS, PRIME, envycontrol (híbrida), CUDA"
    [laptop]="Portátil: power-profiles-daemon, thermald, brillo"
    [bluetooth]="Bluetooth: bluez y blueman"
    [msi]="MSI: msi-ec, MControlCenter, regla udev"
)

detect_hardware() {
    local -a found=()
    local dev class vendor
    local gpu_intel=0 gpu_amd=0 gpu_nvidia=0
    for dev in /sys/bus/pci/devices/*; do
        class=$(<"$dev/class") vendor=$(<"$dev/vendor")
        [[ $class == 0x03* ]] || continue
        case $vendor in
            0x8086) gpu_intel=1 ;;
            0x1002) gpu_amd=1 ;;
            0x10de) gpu_nvidia=1 ;;
        esac
    done
    if grep -qm1 GenuineIntel /proc/cpuinfo || ((gpu_intel)); then found+=(intel); fi
    if grep -qm1 AuthenticAMD /proc/cpuinfo || ((gpu_amd)); then found+=(amd); fi
    ((gpu_nvidia)) && found+=(nvidia)
    compgen -G '/sys/class/power_supply/BAT*' >/dev/null && found+=(laptop)
    compgen -G '/sys/class/bluetooth/hci*' >/dev/null && found+=(bluetooth)
    grep -qi 'Micro-Star' /sys/class/dmi/id/sys_vendor 2>/dev/null && found+=(msi)
    printf '%s\n' "${found[@]}"
}

describe_hardware() {
    local gpus
    gpus=$(lspci 2>/dev/null | grep -E 'VGA|3D|Display' | sed 's/^[^:]*: //' | paste -sd ';' || true)
    log_info "Equipo: $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/class/dmi/id/product_name 2>/dev/null)"
    [[ -n $gpus ]] && log_info "GPU: $gpus"
}
