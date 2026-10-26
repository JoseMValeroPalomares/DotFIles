# shellcheck shell=bash
# Perfil MSI (Katana GF66): módulo msi-ec, MControlCenter y regla udev para usarlo sin root

hw_msi() {
    install_packages hw-msi
    local rule=/etc/udev/rules.d/99-msi-ec.rules
    if ! cmp -s "$DOTFILES/hardware/files/99-msi-ec.rules" "$rule"; then
        install_system_file "$DOTFILES/hardware/files/99-msi-ec.rules" "$rule" 644
        run_sudo udevadm control --reload-rules
    else
        log_ok "$rule ya está al día"
    fi
    apply_seeds msi

    local grub=/etc/default/grub param=acpi_enforce_resources=lax
    if [[ -f $grub ]] && ! grep -q "$param" "$grub"; then
        log_info "En este portátil GRUB arranca con '$param' (sensores/EC de MSI)."
        if confirm "¿Añadirlo a GRUB_CMDLINE_LINUX_DEFAULT y regenerar grub.cfg?" n; then
            backup_system_file "$grub"
            run_sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"/\1 $param\"/" "$grub"
            run_sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
    fi
}
