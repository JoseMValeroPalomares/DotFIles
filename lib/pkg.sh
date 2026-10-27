# shellcheck shell=bash
# Paquetes: pacman, helper de AUR (yay o paru) y listas de packages/*.txt

PKG_DIR="$DOTFILES/packages"
AUR_HELPER=""

pacman_flags() {
    local -a f=(--needed)
    ((ASSUME_YES)) && f+=(--noconfirm)
    printf '%s\n' "${f[@]}"
}

# Lee una lista quitando comentarios y líneas vacías
read_list() {
    [[ -f $1 ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$' || true
}

pkg_installed() { pacman -Qq "$1" >/dev/null 2>&1; }

detect_aur_helper() {
    local h
    for h in yay paru; do
        if has "$h"; then AUR_HELPER=$h; return 0; fi
    done
    return 1
}

install_yay() {
    log_info "No hay helper de AUR: se instalará yay-bin desde AUR (compila con makepkg)."
    confirm "¿Instalar yay?" s || { log_warn "Sin helper de AUR: se omiten los paquetes de AUR"; return 1; }
    local tmp
    local -a mf=(-si --needed)
    ((ASSUME_YES)) && mf+=(--noconfirm)
    tmp=$(mktemp -d)
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    if ((DRY_RUN)); then
        run makepkg "${mf[@]}"
    else
        (cd "$tmp/yay-bin" && makepkg "${mf[@]}") || return 1
    fi
    rm -rf "$tmp"
    AUR_HELPER=yay
}

# base-devel, git y stow + helper de AUR
bootstrap() {
    log_step "Preparación: base-devel, git, stow y helper de AUR"
    has pacman || die "Esto es para Arch Linux (no encuentro pacman)"
    local -a missing=() flags=()
    local p
    for p in base-devel git stow; do pkg_installed "$p" || missing+=("$p"); done
    mapfile -t flags < <(pacman_flags)
    log_info "Actualizando el sistema antes de instalar (evita paquetes a medio actualizar)"
    run_sudo pacman -Syu "${flags[@]}" || die "Falló pacman -Syu"
    if ((${#missing[@]})); then
        run_sudo pacman -S "${flags[@]}" "${missing[@]}" || die "No se pudieron instalar: ${missing[*]}"
    else
        log_ok "base-devel, git y stow ya están instalados"
    fi
    if detect_aur_helper; then
        log_ok "Helper de AUR: $AUR_HELPER"
    else
        install_yay || true
    fi
}

# install_packages <lista>   (packages/<lista>.pacman.txt y packages/<lista>.aur.txt)
install_packages() {
    local name=$1 p rc=0
    local -a want=() missing=() repo=() unknown=() aur=() flags=()
    mapfile -t flags < <(pacman_flags)

    mapfile -t want < <(read_list "$PKG_DIR/$name.pacman.txt")
    for p in "${want[@]}"; do pkg_installed "$p" || missing+=("$p"); done
    for p in "${missing[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else unknown+=("$p"); fi
    done
    if ((${#unknown[@]})); then
        log_warn "No están en los repos oficiales: ${unknown[*]}"
        mark err "$name: paquetes no encontrados (${unknown[*]})"
    fi
    if ((${#repo[@]})); then
        log_info "pacman ($name): ${repo[*]}"
        run_sudo pacman -S "${flags[@]}" "${repo[@]}" || { log_error "pacman falló en $name"; rc=1; }
    fi

    mapfile -t want < <(read_list "$PKG_DIR/$name.aur.txt")
    for p in "${want[@]}"; do pkg_installed "$p" || aur+=("$p"); done
    if ((${#aur[@]})); then
        if [[ -z $AUR_HELPER ]]; then
            log_warn "Sin helper de AUR, se omiten: ${aur[*]}"
            mark skip "$name: AUR sin helper (${aur[*]})"
        else
            log_info "AUR ($name): ${aur[*]}"
            run "$AUR_HELPER" -S "${flags[@]}" "${aur[@]}" || { log_error "$AUR_HELPER falló en $name"; rc=1; }
        fi
    fi

    if ((${#repo[@]} + ${#aur[@]} == 0)) && ((${#unknown[@]} == 0)); then
        [[ -f $PKG_DIR/$name.pacman.txt || -f $PKG_DIR/$name.aur.txt ]] && log_ok "Paquetes de $name ya instalados"
    fi
    return "$rc"
}
