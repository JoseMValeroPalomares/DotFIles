#!/usr/bin/env bash
# Prepara la build: clona hyprplane en el commit fijado, aplica el parche y compila en ./build/.
# No toca nada fuera de esta carpeta. Rehacerlo tras actualizar Hyprland (el plugin va atado a su versión).
set -euo pipefail

PROJ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$PROJ/build/src"
UPSTREAM="https://github.com/HarryC913/hyprplane"
COMMIT="3aa8a1ff8c07c89670a9f049fd981eaaa43c18f4" # "Port to Hyprland 0.56.2 API"

if [[ ! -d $SRC/.git ]]; then
  git clone -q "$UPSTREAM" "$SRC"
  git -C "$SRC" checkout -q "$COMMIT"
  # Capturas de ImageMagick subidas por error al repo (json/os/sys): no forman parte del plugin
  rm -f "$SRC/json" "$SRC/os" "$SRC/sys"
  git -C "$SRC" apply "$PROJ/hyprplane-lua.patch"
  echo "Clonado $COMMIT y parche aplicado"
fi

headers=$(pkg-config --modversion hyprland)
running=$(hyprctl version -j 2>/dev/null | python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("version",""))' || true)
[[ -z $running || $running == "$headers" ]] || {
  echo "Hyprland $running en marcha pero las cabeceras son de $headers: cierra sesión y vuelve a entrar" >&2
  exit 1
}

cmake -Wno-unused-cli -DCMAKE_BUILD_TYPE=Release -S "$SRC" -B "$SRC/build" >/dev/null
cmake --build "$SRC/build" -j"$(nproc)" >/dev/null
echo "Compilado para Hyprland $headers: $SRC/build/hyprplane.so"
