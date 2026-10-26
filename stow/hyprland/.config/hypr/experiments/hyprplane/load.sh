#!/usr/bin/env bash
# Carga hyprplane (con el parche Lua) SOLO en esta sesión: no toca hyprland.lua. Cerrar sesión lo deja limpio.
# `hyprctl reload` borra atajos y eventos del experimento pero el plugin sigue cargado: vuelve a ejecutar
# este script o usa clean.sh.
set -euo pipefail

PROJ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$PROJ/build/src/build"

[[ -f $BUILD/hyprplane.so ]] || "$PROJ/setup.sh"

if ! hyprctl plugin list | grep -q '^Plugin hyprplane '; then
  # dlopen reutiliza lo ya cargado desde la misma ruta: cargar siempre desde una ruta con el hash del contenido
  SO="$BUILD/load/hyprplane-$(sha256sum "$BUILD/hyprplane.so" | cut -c1-12).so"
  mkdir -p "$BUILD/load" && cp -n "$BUILD/hyprplane.so" "$SO"
  hyprctl plugin load "$SO" >/dev/null
  # Las funciones hl.plugin.* se inyectan al crear la VM de Lua: recargar para verlas
  hyprctl reload >/dev/null
fi
hyprctl eval "dofile(\"$PROJ/hyprplane.lua\")" >/dev/null
errs=$(hyprctl configerrors)
[[ -z $errs ]] || { echo "Errores de config:"; echo "$errs"; exit 1; }
echo "hyprplane cargado: el workspace 10 (SUPER+0) es un plano infinito."
