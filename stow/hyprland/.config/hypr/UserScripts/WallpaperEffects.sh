#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Efectos para el fondo de pantalla con ImageMagick (SUPER+SHIFT+U)
# El menú muestra una vista previa de cada efecto sobre el fondo actual. Las imágenes se generan
# una vez por fondo, a la resolución del monitor y en paralelo, y se guardan en caché:
# aplicar un efecto ya calculado es inmediato.

# --- Configuración ---
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"   # original (lo copia WallustSwww.sh)
wallpaper_output="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"   # fondo del menú de rofi
cache_root="$HOME/.cache/wallpaper-effects"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_theme="$HOME/.config/rofi/config-wallpaper-effect.rasi"
palette_file="$HOME/.config/hypr/wallust/wallust-hyprland.lua"
iDIR="$HOME/.config/swaync/images"
AWWW_PARAMS=(--transition-fps 60 --transition-type wipe --transition-duration 2 --transition-bezier ".43,1.19,1,.4")

# Orden del menú: identificador|nombre
EFFECTS=(
    "none|Sin efecto"
    "blur|Desenfoque suave"
    "frost|Cristal esmerilado"
    "focus|Enfoque"
    "dream|Sueño"
    "dark|Oscurecer"
    "vignette|Viñeta suave"
    "duotone|Duotono"
    "tint|Tinte"
    "desat|Desaturado"
    "bw-soft|Blanco y negro suave"
    "bw|Blanco y negro contraste"
    "sepia|Sepia suave"
    "pixel|Pixelado"
    "illus|Ilustración"
)

# render_effect <id> <base> <salida> <ancho> <alto> <oscuro> <claro> <acento>
# Los colores salen de la paleta de wallust del fondo original (duotono y tinte)
render_effect() {
    local id="$1" in="$2" out="$3" w="$4" h="$5" dark="$6" light="$7" accent="$8"
    case "$id" in
        none)     cp -f "$in" "$out" ;;
        blur)     magick "$in" -blur 0x12 "$out" ;;
        frost)    magick "$in" -blur 0x30 -fill black -colorize 15% "$out" ;;
        focus)    magick "$in" -blur 0x8 -fill black -colorize 25% "$out" ;;
        dream)    magick "$in" -blur 0x20 -modulate 105,145 "$out" ;;
        dark)     magick "$in" -fill black -colorize 35% "$out" ;;
        vignette) magick "$in" \( -size "${w}x${h}" radial-gradient:white-gray5 -level 0%,85% \) \
                      -compose multiply -composite "$out" ;;
        duotone)  magick "$in" -colorspace gray -auto-level +level-colors "$dark,$light" "$out" ;;
        tint)     magick "$in" -fill "$accent" -colorize 25% "$out" ;;
        desat)    magick "$in" -modulate 100,35 "$out" ;;
        bw-soft)  magick "$in" -colorspace gray -sigmoidal-contrast 4,50% "$out" ;;
        bw)       magick "$in" -colorspace gray -sigmoidal-contrast 10,40% "$out" ;;
        sepia)    magick "$in" \( +clone -sepia-tone 80% \) -compose blend -define compose:args=55 -composite "$out" ;;
        pixel)    magick "$in" -sample 4% -sample "${w}x${h}!" "$out" ;;
        illus)    magick "$in" -paint 3 -modulate 100,120 "$out" ;;
        *)        return 1 ;;
    esac
}

# --- Modo interno: genera un efecto y su miniatura (lo lanza xargs en paralelo) ---
if [[ "$1" == --render ]]; then
    id="$2" cache="$3"
    read -r w h dark light accent < "$cache/params"
    render_effect "$id" "$cache/base.png" "$cache/$id.tmp.png" "$w" "$h" "$dark" "$light" "$accent" &&
        mv -f "$cache/$id.tmp.png" "$cache/$id.png" &&
        magick "$cache/$id.png" -resize 480x270 "$cache/thumb-$id.png"
    exit
fi

notify() { notify-send -e -u low -h string:x-canonical-private-synchronous:wallpaper_effects -i "$iDIR/ja.png" "$@"; }

pidof rofi >/dev/null && pkill -x rofi

if [[ ! -f "$wallpaper_current" ]]; then
    notify "Efectos de fondo" "Elige antes un fondo con SUPER+U"
    exit 1
fi

read -r focused_monitor mon_w mon_h < <(
    hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.name) \(.width) \(.height)"'
)

# Caché por fondo y resolución (WallustSwww.sh vuelve a copiar el original en cada cambio de fondo)
key="$(stat -c '%s-%Y' "$wallpaper_current")-${mon_w}x${mon_h}"
cache="$cache_root/$key"

if [[ ! -f "$cache/ready" ]]; then
    notify "Efectos de fondo" "Preparando vistas previas…"
    rm -rf -- "${cache_root:?}"  # solo se guarda el fondo actual
    mkdir -p "$cache"

    # Paleta del fondo original: oscuro (color1), claro (color14) y acento (color13)
    declare -A pal
    while IFS='"' read -r name _ value _; do
        name="${name//[[:space:]=]/}"
        [[ "$value" =~ ^rgb\(([0-9A-Fa-f]{6})\)$ ]] && pal[$name]="#${BASH_REMATCH[1]}"
    done < "$palette_file"
    echo "$mon_w $mon_h ${pal[color1]:-#0C1737} ${pal[color14]:-#7CA5D7} ${pal[color13]:-#6E93C4}" > "$cache/params"

    # Base a la resolución del monitor (los fondos 4K tardaban 3-7 s por efecto)
    magick "$wallpaper_current" -resize "${mon_w}x${mon_h}^" -gravity center -extent "${mon_w}x${mon_h}" "$cache/base.png"

    for e in "${EFFECTS[@]}"; do echo "${e%%|*}"; done |
        xargs -P "$(nproc)" -I{} "${BASH_SOURCE[0]}" --render {} "$cache"
    cp -f "$cache/none.png" "$wallpaper_output"  # el menú muestra el fondo nuevo
    touch "$cache/ready"
fi

# --- Menú con miniaturas; marca el efecto aplicado ---
applied=$(cat "$cache/applied" 2>/dev/null)
selected=0
for i in "${!EFFECTS[@]}"; do
    [[ "${EFFECTS[i]%%|*}" == "$applied" ]] && selected=$i
done
menu() {
    local e
    for e in "${EFFECTS[@]}"; do
        printf '%s\0icon\x1f%s\n' "${e#*|}" "$cache/thumb-${e%%|*}.png"
    done
}
row=$(menu | rofi -dmenu -i -no-custom -format i -show-icons -selected-row "$selected" -config "$rofi_theme")
[[ "$row" =~ ^[0-9]+$ ]] || exit 0

id="${EFFECTS[row]%%|*}"
name="${EFFECTS[row]#*|}"
if [[ ! -f "$cache/$id.png" ]]; then
    notify "Efectos de fondo" "No se ha podido generar «$name»"
    exit 1
fi

# --- Aplicar: fondo, colores de wallust (antes de recargar la barra) y menús ---
if [[ "$id" == none ]]; then
    image="$wallpaper_current"   # el original a resolución completa
else
    image="$cache/$id.png"
fi
awww img -o "$focused_monitor" "$image" "${AWWW_PARAMS[@]}"
cp -f "$cache/$id.png" "$wallpaper_output"
echo "$id" > "$cache/applied"
wallust run -s "$image"
"$SCRIPTSDIR/Refresh.sh"
notify "Efectos de fondo" "$name"
