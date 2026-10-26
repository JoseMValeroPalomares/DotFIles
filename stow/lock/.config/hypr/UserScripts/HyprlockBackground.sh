#!/usr/bin/env bash
# Fondo de hyprlock con menú propio (SUPER+CTRL+U).
#
#   HyprlockBackground.sh          menú rofi: aleatorio, fondo del escritorio o una imagen
#   HyprlockBackground.sh --apply  prepara fondo y colores según el modo guardado
#   HyprlockBackground.sh --next   lo lanza hyprlock al bloquear: tras cargar el fondo actual,
#                                  prepara el del próximo bloqueo (en modo aleatorio cambia)
#
# hyprlock.conf lee siempre ~/.cache/hyprlock/background y ~/.cache/hyprlock/colors.conf (enlaces).

state="$HOME/.config/hypr/UserConfigs/HyprlockBackground" # current | random | /ruta/a/imagen
cache="$HOME/.cache/hyprlock"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
desktop_colors="$HOME/.config/hypr/wallust/wallust-hyprlock.conf"
wallust_toml="$HOME/.config/wallust/wallust.toml"
wallust_template="$HOME/.config/wallust/templates/colors-hyprlock.conf"
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
iDIR="$HOME/.config/swaync/images"

mkdir -p "$cache"

# Solo formatos que hyprlock dibuja (sin vídeos ni gif animados)
list_images() {
  find -L "$wallDIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0
}

mode() {
  local m
  m=$(cat "$state" 2>/dev/null)
  echo "${m:-current}"
}

# ln + mv: el enlace nunca falta mientras hyprlock lo lee
link() {
  ln -sfn "$1" "$2.tmp" && mv -Tf "$2.tmp" "$2"
}

# Paleta de la imagen con una config aislada de wallust: solo escribe la plantilla de hyprlock,
# sin tocar el tema del escritorio ni las secuencias de los terminales (-s)
colors_from() {
  local img="$1" dir="$cache/wallust"
  mkdir -p "$dir/templates"
  ln -sfn "$wallust_template" "$dir/templates/colors-hyprlock.conf"
  {
    sed -n '1,/^\[templates\]/p' "$wallust_toml"
    echo "hyprlock.template = 'colors-hyprlock.conf'"
    echo "hyprlock.target = '$cache/colors-bg.conf.new'"
  } >"$dir/wallust.toml"
  timeout 10 wallust run -s -q -d "$dir" "$img" && mv -f "$cache/colors-bg.conf.new" "$cache/colors-bg.conf"
}

use_image() {
  local img="$1"
  if colors_from "$img"; then
    link "$img" "$cache/background"
    link "$cache/colors-bg.conf" "$cache/colors.conf"
  else
    # Si wallust falla, la imagen va con los colores del escritorio
    link "$img" "$cache/background"
    link "$desktop_colors" "$cache/colors.conf"
  fi
}

apply() {
  local m img
  m=$(mode)
  case "$m" in
  random)
    img=$(list_images | shuf -z -n1 | tr -d '\0')
    [[ -n "$img" ]] && use_image "$img" && return
    ;;
  current) ;;
  *)
    [[ -f "$m" ]] && use_image "$m" && return
    ;;
  esac
  # current, o si la imagen elegida ya no existe / no hay imágenes
  link "$wallpaper_current" "$cache/background"
  link "$desktop_colors" "$cache/colors.conf"
}

menu() {
  local random_icon current_name current_label=". Escritorio" random_label=". Aleatorio"
  local -A paths
  local pics p name choice names

  mapfile -d '' pics < <(list_images)
  if ((${#pics[@]} == 0)); then
    notify-send -i "$iDIR/error.png" "Pantalla de bloqueo" "No hay imágenes en $wallDIR"
    exit 1
  fi
  random_icon="${pics[RANDOM % ${#pics[@]}]}"
  for p in "${pics[@]}"; do
    name="${p##*/}"
    [[ -z "${paths[$name]}" ]] && paths[$name]="$p"
  done
  # Nombres ordenados en un array (antes «for name in $(…)» partía los que llevan espacios)
  mapfile -t names < <(printf '%s\n' "${!paths[@]}" | sort)

  case "$(mode)" in
  current) current_name="escritorio" ;;
  random) current_name="aleatorio" ;;
  *) current_name=$(basename "$(mode)") ;;
  esac

  # Miniaturas en caché, como WallpaperSelect.sh; las dos filas especiales llevan su nombre pintado encima
  source "$HOME/.config/hypr/UserScripts/lib/wallthumbs.sh"
  ensure_thumbs "${paths[@]}"
  labeled_thumb "$random_icon" "Aleatorio" "$THUMB_DIR/_lock_aleatorio.jpg"
  labeled_thumb "$wallpaper_current" "Escritorio" "$THUMB_DIR/_lock_escritorio.jpg"

  choice=$(
    {
      printf "%s\x00icon\x1f%s\n" "$random_label" "$THUMB_DIR/_lock_aleatorio.jpg"
      printf "%s\x00icon\x1f%s\n" "$current_label" "$THUMB_DIR/_lock_escritorio.jpg"
      for name in "${names[@]}"; do
        printf "%s\x00icon\x1f%s/%s.jpg\n" "$name" "$THUMB_DIR" "${paths[$name]//\//#}"
      done
    } | rofi -i -dmenu -config "$rofi_theme" \
      -theme-str "entry{placeholder:\"Fondo del bloqueo · ahora: ${current_name//\"/} · buscar por nombre\";}"
  )

  case "$choice" in
  "") exit 0 ;;
  "$random_label") echo random >"$state" ;;
  "$current_label") echo current >"$state" ;;
  *)
    [[ -n "${paths[$choice]}" ]] || exit 1
    printf '%s\n' "${paths[$choice]}" >"$state"
    ;;
  esac

  apply
  notify-send -i "$cache/background" "Pantalla de bloqueo" "Fondo: $(basename "$(readlink -f "$cache/background")")"
}

case "$1" in
--apply) apply ;;
--next)
  # Cierra las copias heredadas de la tubería de hyprlock: si no, espera a este proceso
  # (~5 s) y mientras tanto redibuja a 144 fps en cada monitor
  for fd in /proc/self/fd/*; do
    n=${fd##*/}
    ((n > 2)) && eval "exec $n>&-" 2>/dev/null
  done
  # hyprlock lanza esto una vez por monitor: solo actúa la primera copia
  exec 9>"$cache/.next.lock"
  flock -n 9 || exit 0
  # Por si hyprlock repitiera el comando: como mucho un cambio por minuto
  [[ -n $(find "$cache/background" -mmin -1 2>/dev/null) ]] && exit 0
  # Espera a que hyprlock haya cargado el fondo actual antes de cambiar el enlace
  sleep 5
  apply
  ;;
*)
  # IFS sin espacios: los nombres de archivo pueden tenerlos
  IFS=$'\n'
  pkill -x rofi
  menu
  ;;
esac
