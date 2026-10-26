# shellcheck shell=bash
# Funciones comunes: registro, ejecución con --dry-run, confirmaciones y resumen.

DRY_RUN=${DRY_RUN:-0}
ASSUME_YES=${ASSUME_YES:-0}
SUMMARY_FILE=${SUMMARY_FILE:-}

if [[ -t 1 ]]; then
    C_0=$'\e[0m' C_B=$'\e[1m' C_DIM=$'\e[2m'
    C_RED=$'\e[31m' C_GRN=$'\e[32m' C_YEL=$'\e[33m' C_BLU=$'\e[34m' C_MAG=$'\e[35m'
else
    C_0='' C_B='' C_DIM='' C_RED='' C_GRN='' C_YEL='' C_BLU='' C_MAG=''
fi

log_step()  { printf '\n%s%s==> %s%s\n' "$C_B" "$C_MAG" "$*" "$C_0"; }
log_info()  { printf '  %s•%s %s\n' "$C_BLU" "$C_0" "$*"; }
log_ok()    { printf '  %s✓%s %s\n' "$C_GRN" "$C_0" "$*"; }
log_warn()  { printf '  %s!%s %s\n' "$C_YEL" "$C_0" "$*" >&2; }
log_error() { printf '  %s✗ %s%s\n' "$C_RED" "$*" "$C_0" >&2; }
log_sudo()  { printf '  %s[sudo]%s %s\n' "$C_YEL$C_B" "$C_0" "$*"; }
die()       { log_error "$*"; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# Resumen final: se guarda en un archivo para que sobreviva a los subshells de cada componente
mark() { # mark ok|skip|err "texto"
    [[ -n $SUMMARY_FILE ]] && printf '%s|%s\n' "$1" "$2" >>"$SUMMARY_FILE"
    return 0
}

# Ejecuta un comando o, con --dry-run, solo lo muestra
run() {
    if ((DRY_RUN)); then
        printf '  %s[dry-run]%s %s\n' "$C_DIM" "$C_0" "$(printf '%q ' "$@")"
        return 0
    fi
    "$@"
}

# Igual que run, pero con sudo y avisando antes
run_sudo() {
    log_sudo "$(printf '%q ' "$@")"
    ((DRY_RUN)) && return 0
    sudo "$@"
}

# confirm "pregunta" [s|n]  -> 0 si la respuesta es sí
confirm() {
    local msg=$1 def=${2:-n} ans hint
    if ((DRY_RUN)); then
        printf '  %s[dry-run]%s se preguntaría: %s\n' "$C_DIM" "$C_0" "$msg"
        return 0
    fi
    ((ASSUME_YES)) && return 0
    if [[ ! -t 0 ]]; then
        [[ $def == s ]]
        return
    fi
    if has gum; then
        local -a args=()
        [[ $def == s ]] || args+=(--default=false)
        gum confirm "${args[@]}" --affirmative="Sí" --negative="No" "$msg"
        return
    fi
    [[ $def == s ]] && hint='[S/n]' || hint='[s/N]'
    read -r -p "  ${C_B}?${C_0} $msg $hint " ans
    ans=${ans:-$def}
    [[ $ans =~ ^[sSyY] ]]
}

# Mantiene sudo vivo mientras dura la instalación
sudo_keepalive() {
    ((DRY_RUN)) && return 0
    log_info "Algunos pasos necesitan sudo (se avisa con ${C_YEL}[sudo]${C_0} antes de cada uno)."
    sudo -v || die "No se pudo obtener sudo"
    while true; do
        sudo -n true 2>/dev/null || true
        sleep 50
        kill -0 "$$" 2>/dev/null || exit 0
    done &
    # shellcheck disable=SC2034  # lo usa cleanup() en install.sh
    SUDO_KEEPALIVE_PID=$!
}

# Habilita y arranca un servicio systemd si no lo está ya: enable_service [--user] nombre
enable_service() {
    local -a scope=()
    if [[ $1 == --user ]]; then scope=(--user); shift; fi
    local unit=$1
    if systemctl "${scope[@]}" is-enabled --quiet "$unit" 2>/dev/null; then
        log_ok "$unit ya está habilitado"
        return 0
    fi
    if ! systemctl "${scope[@]}" cat "$unit" >/dev/null 2>&1; then
        ((DRY_RUN)) || { log_warn "$unit no existe (¿falta el paquete?)"; return 0; }
    fi
    if ((${#scope[@]})); then
        run systemctl --user enable --now "$unit"
    else
        run_sudo systemctl enable --now "$unit"
    fi
}

# Añade el usuario a un grupo si existe y aún no pertenece
add_to_group() {
    local group=$1
    getent group "$group" >/dev/null || { log_warn "El grupo $group no existe"; return 0; }
    if id -nG "$USER" | tr ' ' '\n' | grep -qx "$group"; then
        return 0
    fi
    run_sudo usermod -aG "$group" "$USER"
    log_info "Añadido a $group (efectivo al volver a iniciar sesión)"
}

# Clona un repo git si la carpeta no existe: git_clone_once url destino
git_clone_once() {
    local url=$1 dest=$2
    if [[ -d $dest/.git || -d $dest && -n $(ls -A "$dest" 2>/dev/null) ]]; then
        log_ok "Ya existe: ${dest/#$HOME/\~}"
        return 0
    fi
    run git clone --depth 1 "$url" "$dest"
}
