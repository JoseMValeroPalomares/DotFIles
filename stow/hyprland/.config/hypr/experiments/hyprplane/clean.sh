#!/usr/bin/env bash
# Deja el proyecto DESACTIVADO Y LIMPIO (el estado en que se aparcó): descarga el plugin (las ventanas
# del plano vuelven a dwindle), quita la línea de hyprland.lua si se añadió, borra la build y el estado.
# Conserva el proyecto (parche, Lua, scripts, CLAUDE.md). Con --purge borra también esta carpeta;
# con --keep-build solo descarga (para recompilar y volver a cargar con load.sh mientras se desarrolla).
set -euo pipefail

PROJ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HYPR="$HOME/.config/hypr"

# 1. Descargar desde la ruta con hash que esté en memoria. Nunca un unload a mano: el uninstall
#    de la build parcheada apaga solo los workspaces con plano (el original encendía los visibles).
if hyprctl plugin list 2>/dev/null | grep -q '^Plugin hyprplane '; then
  so=$(awk '$6 ~ /\/load\/hyprplane-[0-9a-f]+\.so$/ && $7 == "" {print $6; exit}' "/proc/$(pidof Hyprland)/maps")
  [[ -n $so ]] && hyprctl plugin unload "$so" >/dev/null && echo "Plugin descargado"
fi

# 2. Integración en hyprland.lua, si se llegó a hacer
sed -i -e '/experiments\/hyprplane/d' -e '/Experimento hyprplane/d' "$HYPR/hyprland.lua"

# 3. Build y estado que puede escribir el plugin
[[ ${1:-} == --keep-build ]] || rm -rf "$PROJ/build"
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/hyprplane" "${XDG_RUNTIME_DIR:-/tmp}/hyprplane-active"

hyprctl reload >/dev/null && echo "Hyprland recargado"

if [[ ${1:-} == --purge ]]; then
  rm -rf "$PROJ"
  sed -i '/<!-- BEGIN hyprplane -->/,/<!-- END hyprplane -->/d' "$HYPR/experiments/README.md"
  sed -i '/experiments\/hyprplane/d' "$HYPR/CLAUDE.md" 2>/dev/null || true
  echo "Proyecto hyprplane borrado por completo."
else
  echo "hyprplane desactivado y limpio (proyecto conservado en $PROJ)."
fi
