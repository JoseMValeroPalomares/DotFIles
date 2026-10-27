#!/usr/bin/env bash
# Arranque en un Arch recién instalado: instala git, clona el repo en ~/dotfiles y lanza install.sh.
#   bash <(curl -fsSL https://raw.githubusercontent.com/JoseMValeroPalomares/DotFIles/main/bootstrap.sh) --first-time
# Cualquier argumento se pasa tal cual a install.sh (por defecto: --first-time).
set -euo pipefail

REPO_URL=${DOTFILES_REPO:-https://github.com/JoseMValeroPalomares/DotFIles.git}
DEST=${DOTFILES_DIR:-$HOME/dotfiles}

((EUID != 0)) || { echo "Ejecútalo con tu usuario, no como root (se pedirá sudo)." >&2; exit 1; }
command -v pacman >/dev/null || { echo "Esto es para Arch Linux." >&2; exit 1; }

if ! command -v git >/dev/null; then
    echo "==> [sudo] Instalando git"
    sudo pacman -Syu --needed --noconfirm git
fi

if [[ -d $DEST/.git ]]; then
    echo "==> $DEST ya existe: actualizando"
    git -C "$DEST" pull --ff-only || echo "  (no se pudo actualizar; se usa lo que hay)"
else
    echo "==> Clonando $REPO_URL en $DEST"
    git clone "$REPO_URL" "$DEST"
fi

cd "$DEST"
(($#)) || set -- --first-time
exec ./install.sh "$@"
