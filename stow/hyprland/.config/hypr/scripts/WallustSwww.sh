#!/usr/bin/env bash
# Wallust: derive colors from the current wallpaper and update templates
# Usage: WallustSwww.sh [--colors] [absolute_path_to_wallpaper]
#   Sin --colors: el fondo ha cambiado. Con tema fijo (ver wallust_fixed) los colores no se tocan.
#   Con --colors: aplica los colores de esa imagen aunque el tema esté fijo y no cuenta como cambio de fondo.

set -euo pipefail

# Inputs and paths
colors_only=false
if [[ "${1:-}" == "--colors" ]]; then
  colors_only=true
  shift
fi
passed_path="${1:-}"
wallust_fixed="$HOME/.config/hypr/UserConfigs/WallustFixed" # existe = tema fijo; lo cambia WallpaperSelect.sh
cache_dir="$(ls -d "$HOME"/.cache/awww/*/ 2>/dev/null | tail -1)"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
# Caché de awww: "\0crop:center\0Lanczos3\0/home/…"; se queda con la ruta.
# Puede estar desfasada: solo se usa si el daemon no responde.
read_cached_wallpaper() {
  local cache_file="$1"
  if [[ -f "$cache_file" ]]; then
    tr '\0' '\n' < "$cache_file" | awk '/^\// {print; exit}'
  fi
}

# awww 0.12: ": HDMI-A-1: 1920x1080, scale: 1, currently displaying: image: /ruta"
read_wallpaper_from_query() {
  local monitor="$1"
  awww query 2>/dev/null | awk -v mon="$monitor" '
    { l = $0; sub(/^[: ]+/, "", l) }
    index(l, mon ": ") == 1 && l ~ /image: / {
      sub(/^.*image: /, "", l)
      print l
      exit
    }
  '
}

# Helper: get focused monitor name (prefer JSON)
get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

# Determine wallpaper_path
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  # Primero el daemon (lo que se ve de verdad); la caché solo como reserva
  current_monitor="$(get_focused_monitor)"
  wallpaper_path="$(read_wallpaper_from_query "$current_monitor")" || true

  if [[ -z "$wallpaper_path" ]]; then
    wallpaper_path="$(read_cached_wallpaper "$cache_dir$current_monitor")" || true
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  # Nothing to do; avoid failing loudly so callers can continue
  exit 0
fi

# Update helpers that depend on the path
if ! $colors_only; then
  ln -sf "$wallpaper_path" "$rofi_link" || true
  mkdir -p "$(dirname "$wallpaper_current")"
  cp -f "$wallpaper_path" "$wallpaper_current" || true
  [[ -e "$wallust_fixed" ]] && exit 0
fi

# Ensure Ghostty directory exists so Wallust can write target even if Ghostty isn't installed
mkdir -p "$HOME/.config/ghostty" || true
wait_for_templates() {
  local start_ts="$1"
  shift
  local files=("$@")
  for _ in {1..50}; do
    local ready=true
    for file in "${files[@]}"; do
      if [[ ! -s "$file" ]]; then
        ready=false
        break
      fi
      local mtime
      mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
      if (( mtime < start_ts )); then
        ready=false
        break
      fi
    done
    $ready && return 0
    sleep 0.1
  done
  return 1
}

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s is used in this repo to keep things quiet and avoid extra prompts
start_ts=$(date +%s)
wallust run -s "$wallpaper_path" || true
wallust_targets=(
  "$HOME/.config/waybar/wallust/colors-waybar.css"
  "$HOME/.config/rofi/wallust/colors-rofi.rasi"
  "$HOME/.config/kitty/wallust-accents.conf"
)
wait_for_templates "$start_ts" "${wallust_targets[@]}" || true

# Iconos de las notificaciones con la paleta nueva
"$HOME/.config/swaync/scripts/gen-icons.py" >/dev/null 2>&1 &

# Kitty: SIGUSR1 recarga kitty.conf (incluye wallust-accents.conf) en las ventanas abiertas
for pid in $(pidof kitty); do kill -SIGUSR1 "$pid" 2>/dev/null || true; done

# Normalize Ghostty palette syntax in case ':' was used by older files
if [ -f "$HOME/.config/ghostty/wallust.conf" ]; then
  sed -i -E 's/^(\s*palette\s*=\s*)([0-9]{1,2}):/\1\2=/' "$HOME/.config/ghostty/wallust.conf" 2>/dev/null || true
fi

# Light wait for Ghostty colors file to be present then signal Ghostty to reload (SIGUSR2)
for _ in 1 2 3; do
  [ -s "$HOME/.config/ghostty/wallust.conf" ] && break
  sleep 0.1
done
if pidof ghostty >/dev/null; then
  for pid in $(pidof ghostty); do kill -SIGUSR2 "$pid" 2>/dev/null || true; done
fi

# Prompt Waybar to reload colors
if command -v waybar-msg >/dev/null 2>&1; then
  waybar-msg cmd reload >/dev/null 2>&1 || true
elif pidof waybar >/dev/null; then
  killall -SIGUSR2 waybar 2>/dev/null || true
fi
