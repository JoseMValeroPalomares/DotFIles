#!/usr/bin/env bash
# Code - OSS: instala las extensiones de packages/code-extensions.txt
# (las "local.*" no están en Open VSX: vienen en stow/code-oss/.vscode-oss/extensions)

post_code_oss() {
    local code ext
    code=$(command -v code-oss || command -v code || true)
    if [[ -z $code ]]; then
        log_warn "No encuentro code-oss: se omiten las extensiones"
        mark skip "code-oss: extensiones (code no instalado)"
        return 0
    fi
    local -a have=()
    mapfile -t have < <("$code" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
    while read -r ext; do
        [[ -z $ext || $ext == \#* || $ext == local.* ]] && continue
        if printf '%s\n' "${have[@]}" | grep -qx "${ext,,}"; then
            continue
        fi
        log_info "Extensión: $ext"
        run "$code" --install-extension "$ext" --force >/dev/null || {
            log_warn "No se pudo instalar $ext (¿no está en Open VSX?)"
            mark err "code-oss: extensión $ext"
        }
    done <"$DOTFILES/packages/code-extensions.txt"
    log_ok "Extensiones de Code revisadas"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_code_oss "$@"
fi
