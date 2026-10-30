#!/usr/bin/env bash
# Selector de fondos de pantalla (SUPER+U): imágenes con awww y vídeos con mpvpaper

# --- Configuración ---
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
confirm_theme="$HOME/.config/rofi/config-wallpaper-confirm.rasi"
iDIR="$HOME/.config/swaync/images"
live_state="$HOME/.config/hypr/UserConfigs/LiveWallpaper" # lo lee configs/Startup_Apps.lua
wallust_fixed="$HOME/.config/hypr/UserConfigs/WallustFixed" # existe = tema fijo; lo respeta WallustSwww.sh

# Transición de awww
AWWW_PARAMS=(--transition-fps 60 --transition-type any --transition-duration 2 --transition-bezier ".43,1.19,1,.4")
PREVIEW_PARAMS=(--transition-fps 60 --transition-type fade --transition-duration 0.4)   # probar: rápido

video_re='\.(mp4|mkv|mov|webm)$'

# Si hay otro menú de rofi abierto, se cierra y se abre este
pidof rofi >/dev/null && pkill -x rofi

# --- Monitor enfocado ---
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "Fondo de pantalla" "No se ha podido detectar el monitor activo"
  exit 1
fi

# Miniaturas cuadradas en caché (el tamaño de la cuadrícula lo fija config-wallpaper.rasi)
source "$HOME/.config/hypr/UserScripts/lib/wallthumbs.sh"

# --- Lista de fondos (imágenes y vídeos), ordenada por ruta ---
mapfile -t PICS < <(find -L "$wallDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) | sort)

if (( ${#PICS[@]} == 0 )); then
  notify-send -i "$iDIR/error.png" "Fondo de pantalla" "No hay fondos en $wallDIR"
  exit 1
fi

RANDOM_PIC="${PICS[RANDOM % ${#PICS[@]}]}"
ensure_thumbs "${PICS[@]}"
random_thumb="$THUMB_DIR/_aleatorio.jpg"
labeled_thumb "$RANDOM_PIC" "Aleatorio" "$random_thumb"

# Casilla del modo: candado y estado, generada una vez por estado. Imprime su ruta.
mode_tile() {
  local glyph=$'\U000F033F' label="Tema fijo: no" out="$THUMB_DIR/_tema-fijo-no.jpg" font
  if [[ -e "$wallust_fixed" ]]; then
    glyph=$'\U000F033E' label="Tema fijo: sí" out="$THUMB_DIR/_tema-fijo-si.jpg"
  fi
  if [[ ! -s "$out" ]]; then
    font=$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font:bold')
    magick -size "${THUMB_SIZE}x${THUMB_SIZE}" xc:'#12141a' -font "$font" -fill '#f2f4f7' -gravity center \
      -pointsize $(( THUMB_SIZE / 2 )) -annotate +0-$(( THUMB_SIZE / 10 )) "$glyph" \
      -pointsize $(( THUMB_SIZE / 9 )) -annotate +0+$(( THUMB_SIZE / 3 )) "$label" -quality 85 "$out"
  fi
  printf '%s' "$out"
}

# Fila 0 = aleatorio; fila 1 = modo; fila N = PICS[N-2]. Los nombres no se ven (más fondos a la vista) pero se puede buscar por ellos.
menu() {
  printf '%s\0icon\x1f%s\n' "aleatorio random" "$random_thumb"
  printf '%s\0icon\x1f%s\n' "tema fijo modo colores wallust" "$(mode_tile)"
  local pic_path
  for pic_path in "${PICS[@]}"; do
    printf '%s\0icon\x1f%s/%s.jpg\n' "${pic_path##*/}" "$THUMB_DIR" "${pic_path//\//#}"   # = thumb_path, sin subproceso
  done
}

# Recordar si el fondo es vídeo o imagen para el próximo inicio de sesión
remember_wallpaper_type() {
  if [[ "${1,,}" =~ $video_re ]]; then
    printf '%s\n' "$1" > "$live_state"
  else
    rm -f "$live_state"
  fi
}

# Arrancar el daemon si no responde y esperar a que lo haga (máx. 2 s)
ensure_awww() {
  if ! awww query &>/dev/null; then
    awww-daemon --format xrgb &
    for _ in {1..20}; do awww query &>/dev/null && break; sleep 0.1; done
  fi
}

apply_image_wallpaper() {
  local image_path="$1"

  pkill -x 'mpvpaper|swaybg|hyprpaper'
  ensure_awww
  awww img -o "$focused_monitor" "$image_path" "${AWWW_PARAMS[@]}"

  # WallustSwww.sh termina cuando las plantillas ya están escritas: no hace falta esperar
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path"
  "$SCRIPTSDIR/Refresh.sh"
}

apply_video_wallpaper() {
  local video_path="$1"

  if ! command -v mpvpaper &>/dev/null; then
    notify-send -i "$iDIR/error.png" "Fondo de pantalla" "mpvpaper no está instalado"
    return 1
  fi

  awww kill 2>/dev/null
  pkill -x 'mpvpaper|swaybg|hyprpaper'
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

apply_selection() {
  remember_wallpaper_type "$1"
  if [[ "${1,,}" =~ $video_re ]]; then
    apply_video_wallpaper "$1"
  else
    apply_image_wallpaper "$1"
  fi
}

# Solo los colores de la imagen: el fondo se queda como está
apply_colors() {
  "$SCRIPTSDIR/WallustSwww.sh" --colors "$1"
  "$SCRIPTSDIR/Refresh.sh"
  notify-send -e -u low -i "$iDIR/ja.png" "Tema" "Colores de ${1##*/}. El fondo no cambia."
}

# Tema fijo: el fondo deja de cambiar los colores. Al desactivarlo se recuperan los del fondo actual.
toggle_fixed_theme() {
  if [[ -e "$wallust_fixed" ]]; then
    rm -f "$wallust_fixed"
    "$SCRIPTSDIR/WallustSwww.sh" --colors
    "$SCRIPTSDIR/Refresh.sh"
    notify-send -e -u low -i "$iDIR/ja.png" "Tema" "Los colores vuelven a seguir al fondo"
  else
    : > "$wallust_fixed"
    notify-send -e -u low -i "$iDIR/ja.png" "Tema" "Tema fijo: el fondo ya no cambia los colores"
  fi
}

# Imagen que se ve ahora en el monitor (para volver a ella tras una prueba). awww query:
# ": HDMI-A-1: 1920x1080, scale: 1, currently displaying: image: /ruta"
current_wallpaper() {
  awww query 2>/dev/null | awk -v mon="$focused_monitor" '
    { l = $0; sub(/^[: ]+/, "", l) }
    index(l, mon ": ") == 1 && l ~ /image: / { sub(/^.*image: /, "", l); print l; exit }'
}

# Prueba: solo la imagen, con transición corta y sin tocar colores (si te la quedas, se aplica entera)
preview() {
  ensure_awww
  awww img -o "$focused_monitor" "$1" "${PREVIEW_PARAMS[@]}"
}

# Menú pequeño abajo, para que se vea el fondo de prueba. Imprime: keep | colors | other | revert
ask_keep() {
  local icon_keep=$'\U000F012C' icon_colors=$'\U000F03D8' icon_other=$'\U000F0450' icon_back=$'\U000F054D' row
  row=$(printf '%s\n' "$icon_keep   Quedarme con este" "$icon_colors   Solo sus colores" "$icon_other   Probar otro" "$icon_back   Volver al anterior" |
    rofi -dmenu -i -no-custom -format i -config "$confirm_theme" -mesg "Probando: <b>$(escape "${1##*/}")</b>")
  case "$row" in
    0) echo keep ;;
    1) echo colors ;;
    2) echo other ;;
    *) echo revert ;;   # «Volver al anterior» o Esc
  esac
}

# Texto con marcado: escapar & < > (\& porque en bash 5.2 & = texto encontrado)
escape() { local s=${1//&/\&amp;}; s=${s//</\&lt;}; printf '%s' "${s//>/\&gt;}"; }

# --- Principal ---
# Intro = poner el fondo · Shift+Intro = probarlo (luego quedarse, probar otro o volver al anterior)
# Ctrl+Intro = solo sus colores
# -format i devuelve el número de fila: el archivo elegido es exacto aunque haya nombres repetidos.
# Shift+Intro y Ctrl+Intro son «kb-accept-alt» y «kb-accept-custom» por defecto en rofi: se mueven para dejarlos libres.
previous=$(current_wallpaper)
selected_row=0
while true; do
  row=$(menu | rofi -dmenu -i -no-custom -format i -config "$rofi_theme" -selected-row "$selected_row" \
    -kb-accept-alt "Alt+Return" -kb-custom-1 "Shift+Return" \
    -kb-accept-custom "Control+Alt+Return" -kb-custom-2 "Control+Return")
  code=$?
  [[ "$row" =~ ^[0-9]+$ ]] || exit 0

  if (( row == 1 )); then              # Casilla del modo
    toggle_fixed_theme
    selected_row=1
    continue
  fi

  if (( row == 0 )); then
    selected_file="$RANDOM_PIC"
  else
    selected_file="${PICS[row - 2]}"
  fi

  if (( code == 11 )); then            # Ctrl+Intro: solo los colores
    if [[ "${selected_file,,}" =~ $video_re ]]; then
      notify-send -e -u low -i "$iDIR/ja.png" "Fondo de pantalla" "Los vídeos no tienen colores que copiar: elige una imagen"
      selected_row=$row
      continue
    fi
    apply_colors "$selected_file"
    exit 0
  fi

  if (( code != 10 )); then            # Intro: poner directamente
    apply_selection "$selected_file"
    exit 0
  fi

  # Shift+Intro: probar
  if [[ "${selected_file,,}" =~ $video_re ]]; then
    notify-send -e -u low -i "$iDIR/ja.png" "Fondo de pantalla" "Los vídeos no se pueden probar: usa Intro"
    selected_row=$row
    continue
  fi
  preview "$selected_file"
  case "$(ask_keep "$selected_file")" in
    keep)
      apply_selection "$selected_file"
      exit 0 ;;
    colors)
      [[ -n "$previous" ]] && preview "$previous"
      apply_colors "$selected_file"
      exit 0 ;;
    other)
      [[ -n "$previous" ]] && preview "$previous"
      selected_row=$row ;;
    revert)
      [[ -n "$previous" ]] && preview "$previous"
      exit 0 ;;
  esac
done
