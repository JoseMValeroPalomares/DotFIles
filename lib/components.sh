# shellcheck shell=bash
# Registro de componentes. Cada componente puede tener (todo opcional):
#   packages/<c>.pacman.txt, packages/<c>.aur.txt  -> paquetes
#   stow/<c>/                                     -> se enlaza en $HOME con stow
#   seeds/<c>/                                    -> se copia a $HOME solo si falta
#   función post_<c> en scripts/<c>.sh            -> pasos extra (plugins, servicios...)

# Orden de instalación
COMPONENTS=(
    base system fonts theme multimedia
    hyprland lock waybar swaync rofi wlogout wallust quickshell ags
    filemanager kitty zsh nano code-oss spicetify
    bin cli apps dev net xdg git wallpapers systemd-user
)

declare -A COMP_DESC=(
    [base]="Sistema base: kernels, red, utilidades, servicios básicos"
    [fonts]="Fuentes (Nerd Fonts, Noto, JetBrains, Victor Mono...)"
    [theme]="GTK/Qt/Kvantum Catppuccin, iconos bessurf, Flat-Remix y cursores"
    [multimedia]="PipeWire, mpv, loupe, yt-dlp"
    [hyprland]="Hyprland (config Lua), uwsm, portales, scripts de ~/.config/hypr"
    [lock]="Bloqueo: hyprlock + hypridle (Ctrl+Alt+L)"
    [waybar]="Waybar (configs, estilos, clima)"
    [swaync]="Centro de notificaciones SwayNC, iconos con wallust y avisos del sistema (notifyd)"
    [rofi]="Rofi: lanzador, menús y temas"
    [wlogout]="wlogout parcheado (menú de energía, Super+L)"
    [wallust]="Wallust: colores a partir del fondo"
    [quickshell]="Quickshell: overview (Super+A)"
    [ags]="AGS (Aylur's GTK Shell): widgets"
    [filemanager]="Thunar con plugins, acciones y miniaturas"
    [kitty]="Terminal kitty"
    [zsh]="Zsh + Oh My Zsh + plugins, tmux"
    [nano]="Nano con resaltado (scopatz/nanorc)"
    [code-oss]="Code - OSS: ajustes, atajos, snippets y extensiones"
    [spicetify]="Spotify + Spicetify (StarryNight, marketplace)"
    [bin]="Scripts propios en ~/.local/bin (brillo, screenshot-ocr)"
    [cli]="Herramientas y configs: btop, fastfetch, cava, ghostty, wezterm..."
    [apps]="Apps: zen-browser, kicad, wireshark, qalculate, mousepad"
    [dev]="Desarrollo: compiladores, Python, Rust, Java, Bun, Arduino"
    [net]="Red: nmap, mtr, arp-scan, lftp, wol..."
    [xdg]="mimeapps.list y carpetas de usuario"
    [git]="Configuración de git (.gitconfig)"
    [wallpapers]="Crea ~/Pictures/wallpapers (los fondos van aparte)"
    [systemd-user]="Servicios de usuario (panel-maestro...) si existe su proyecto"
    [system]="Ajustes de /etc: pacman, zram, sysctl, reflector, idioma, autologin tty1 (sudo)"
)

# Dependencias recomendadas (solo se avisa; nada falla si faltan)
# shellcheck disable=SC2034  # se usa en install.sh
declare -A COMP_RECOMMENDS=(
    [lock]="hyprland wallust"
    [waybar]="hyprland swaync"
    [rofi]="wallust"
    [wlogout]="hyprland lock"
    [quickshell]="hyprland wallust"
    [hyprland]="waybar swaync rofi lock wallust kitty filemanager"
    [kitty]="fonts"
    [code-oss]="wallust"
)

# shellcheck disable=SC2034  # se usa en install.sh
MINIMAL_COMPONENTS=(zsh kitty nano)

is_component() {
    local c
    for c in "${COMPONENTS[@]}"; do [[ $c == "$1" ]] && return 0; done
    return 1
}

# ¿Está ya en el sistema? (su primer archivo de stow existe en $HOME, o sus paquetes)
component_present() {
    local c=$1 first p
    if [[ -d $STOW_DIR/$c ]]; then
        first=$(find "$STOW_DIR/$c" \( -type f -o -type l \) ! -path "$STOW_DIR/$c/README.md" -print -quit)
        [[ -n $first && -e $HOME/${first#"$STOW_DIR/$c"/} ]] && return 0
        return 1
    fi
    p=$(read_list "$PKG_DIR/$c.pacman.txt" | head -1)
    [[ -n $p ]] && pkg_installed "$p"
}

list_components() {
    local c
    for c in "${COMPONENTS[@]}"; do
        printf '  %-13s %s\n' "$c" "${COMP_DESC[$c]}"
    done
}

# Ejecuta los pasos de un componente (pensado para ir dentro de un subshell con set -e)
install_component() {
    local c=$1 fn
    log_step "Componente: $c — ${COMP_DESC[$c]}"
    if ((NO_PACKAGES)); then
        log_info "Paquetes omitidos (--no-packages)"
    else
        install_packages "$c" || mark err "$c: fallo instalando paquetes (se sigue con la config)"
    fi
    stow_package "$c"
    apply_seeds "$c"
    fn="post_${c//-/_}"
    if declare -F "$fn" >/dev/null; then
        "$fn"
    fi
}
