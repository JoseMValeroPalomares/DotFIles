#!/usr/bin/env bash
# Oh My Zsh (no interactivo), plugins externos y cambio de shell (preguntando)

post_zsh() {
    local omz="$HOME/.oh-my-zsh" custom="$HOME/.config/zsh/custom"

    if [[ -d $omz ]]; then
        log_ok "Oh My Zsh ya instalado"
    else
        log_info "Instalando Oh My Zsh (sin tocar tu .zshrc)"
        local tmp
        tmp=$(mktemp)
        run curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$tmp"
        run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$tmp" --unattended
        rm -f "$tmp"
    fi

    local kind name url
    while read -r kind name url; do
        [[ -z $kind || $kind == \#* ]] && continue
        git_clone_once "$url" "$custom/${kind}s/$name"
    done <"$DOTFILES/scripts/zsh-plugins.txt"

    local zsh_bin current
    zsh_bin=$(command -v zsh || echo /usr/bin/zsh)
    current=$(getent passwd "$USER" | cut -d: -f7)
    if [[ $current == "$zsh_bin" ]]; then
        log_ok "Tu shell ya es zsh"
    elif confirm "¿Cambiar tu shell de $current a $zsh_bin con chsh?" n; then
        run chsh -s "$zsh_bin"
    else
        mark skip "zsh: shell por defecto sin cambiar"
    fi
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_zsh "$@"
fi
