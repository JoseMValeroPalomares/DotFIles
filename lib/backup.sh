# shellcheck shell=bash
# Copias de seguridad: nada se borra; lo que estorba se mueve a ~/.dotfiles-backup/<fecha>/

BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

# Mueve un archivo/enlace de $HOME al backup conservando su ruta relativa
backup_path() {
    local target=$1 rel dest
    rel=${target#"$HOME"/}
    dest="$BACKUP_DIR/home/$rel"
    log_info "backup: ~/$rel → ${dest/#$HOME/\~}"
    run mkdir -p "$(dirname "$dest")"
    run mv -- "$target" "$dest"
}

# Copia un archivo de sistema al backup antes de cambiarlo (con sudo)
backup_system_file() {
    local target=$1 dest="$BACKUP_DIR/system$1"
    [[ -e $target ]] || return 0
    log_info "backup: $target → ${dest/#$HOME/\~}"
    run mkdir -p "$(dirname "$dest")"
    run_sudo cp -a -- "$target" "$dest"
    run_sudo chown "$USER:" "$dest"
}

# Instala un archivo de sistema del repo si cambia: install_system_file origen destino [modo]
install_system_file() {
    local src=$1 dest=$2 mode=${3:-644}
    if [[ -e $dest ]] && cmp -s "$src" "$dest"; then
        log_ok "$dest ya está al día"
        return 0
    fi
    backup_system_file "$dest"
    run_sudo install -Dm"$mode" "$src" "$dest"
}
