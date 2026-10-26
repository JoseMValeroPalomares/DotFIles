# shellcheck shell=bash
# Enlaces con GNU Stow (stow/<componente>) y semillas copiadas (seeds/<componente>)

STOW_DIR="$DOTFILES/stow"
SEEDS_DIR="$DOTFILES/seeds"

# ¿El destino ya apunta (directa o indirectamente) a nuestro archivo del repo?
is_our_link() {
    [[ -L $1 ]] && [[ $(readlink -f -- "$1") == "$(readlink -f -- "$2")" ]]
}

# Enlaza stow/<pkg> en $HOME. Lo que ya exista y no sea nuestro se mueve al backup antes.
stow_package() {
    local pkg=$1 dir="$STOW_DIR/$1" src rel tgt
    local -a conflicts=()
    [[ -d $dir ]] || return 0
    while IFS= read -r -d '' src; do
        rel=${src#"$dir"/}
        tgt="$HOME/$rel"
        if [[ -e $tgt || -L $tgt ]]; then
            is_our_link "$tgt" "$src" && continue
            conflicts+=("$tgt")
        fi
    done < <(find "$dir" \( -type f -o -type l \) ! -name '.gitkeep' -print0)

    if ((DRY_RUN)); then
        if ((${#conflicts[@]})); then
            log_info "${#conflicts[@]} archivo(s) existentes irían a ${BACKUP_DIR/#$HOME/\~}/home/, p. ej.:"
            printf '      %s\n' "${conflicts[@]:0:4}" | sed "s|^      $HOME|      ~|"
        fi
        # Simulación contra un destino vacío: muestra los enlaces que se crearían
        local tmp lines
        tmp=$(mktemp -d)
        lines=$(stow --no-folding -n -v -d "$STOW_DIR" -t "$tmp" -S "$pkg" 2>&1 | grep '^LINK' || true)
        rm -rf "$tmp"
        log_info "stow -n ($pkg): $(grep -c . <<<"$lines") enlace(s), p. ej.:"
        head -3 <<<"$lines" | sed 's/^/      /'
        return 0
    fi
    for tgt in "${conflicts[@]}"; do backup_path "$tgt"; done
    ((${#conflicts[@]})) && log_info "${#conflicts[@]} archivo(s) movidos al backup"
    stow --no-folding -d "$STOW_DIR" -t "$HOME" -R "$pkg"
    log_ok "Enlazado: $pkg"
}

# Copia seeds/<pkg> a $HOME solo para lo que no exista (nunca sobrescribe)
apply_seeds() {
    local pkg=$1 dir="$SEEDS_DIR/$1" n
    [[ -d $dir ]] || return 0
    n=$(rsync -a --ignore-existing --dry-run --out-format='%n' "$dir/" "$HOME/" | grep -cv '/$' || true)
    if ((n == 0)); then
        log_ok "Semillas de $pkg ya presentes"
        return 0
    fi
    if ((DRY_RUN)); then
        log_info "Se copiarían $n archivo(s) nuevos de seeds/$pkg (los existentes no se tocan)"
        return 0
    fi
    rsync -a --ignore-existing "$dir/" "$HOME/"
    log_ok "Copiados $n archivo(s) de seeds/$pkg"
}

# Deshace los enlaces de un componente (no toca las semillas ni el backup)
unstow_package() {
    [[ -d $STOW_DIR/$1 ]] || return 0
    run stow --no-folding -d "$STOW_DIR" -t "$HOME" -D "$1"
}
