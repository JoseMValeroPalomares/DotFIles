# shellcheck shell=bash
# Carga todas las librerías, los post-instaladores y los perfiles de hardware.
# Uso: DOTFILES=/ruta/al/repo; source "$DOTFILES/lib/load.sh"

: "${DOTFILES:?DOTFILES no definido}"
NO_PACKAGES=${NO_PACKAGES:-0}
# shellcheck disable=SC2034  # evita que los post-instaladores se relancen al cargarse
DOTFILES_LOADED=1

# shellcheck source=lib/common.sh
source "$DOTFILES/lib/common.sh"
# shellcheck source=lib/backup.sh
source "$DOTFILES/lib/backup.sh"
# shellcheck source=lib/pkg.sh
source "$DOTFILES/lib/pkg.sh"
# shellcheck source=lib/stow.sh
source "$DOTFILES/lib/stow.sh"
# shellcheck source=lib/ui.sh
source "$DOTFILES/lib/ui.sh"
# shellcheck source=lib/hardware.sh
source "$DOTFILES/lib/hardware.sh"
# shellcheck source=lib/components.sh
source "$DOTFILES/lib/components.sh"

for _f in "$DOTFILES"/scripts/post/*.sh "$DOTFILES"/hardware/*.sh; do
    # shellcheck source=/dev/null
    [[ -f $_f ]] && source "$_f"
done
unset _f

# Para scripts sueltos: ./scripts/post/spicetify.sh se puede ejecutar por sí solo
standalone() { # standalone <función> [args...]
    set -euo pipefail
    detect_aur_helper || true
    "$@"
}
