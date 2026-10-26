#!/usr/bin/env bash
# Miniaturas de fondos para los menús de rofi (WallpaperSelect.sh y HyprlockBackground.sh).
# Se cargan con «source». Cuadradas (rofi reserva un hueco cuadrado por icono) y pequeñas: rofi ya no
# decodifica PNG de 4K para cada icono. Se generan una vez, en paralelo, y se rehacen si el fondo cambia.

THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
THUMB_SIZE=336   # px (se muestran a 168: nítidas también con escala 2)

# Ruta de la miniatura de un fondo (la ruta completa, con «/» → «#», es el nombre; «%» no: magick lo
# interpreta en el nombre de salida como código de formato, %d, %o…)
thumb_path() { printf '%s/%s.jpg' "$THUMB_DIR" "${1//\//#}"; }

# Genera una miniatura: imagen (primer fotograma si es GIF) o fotograma del segundo 1 si es vídeo
_wallthumb_make() {
    local src="$1" out="$2" tmp="$2.tmp.jpg"
    case "${src,,}" in
        *.mp4|*.mkv|*.mov|*.webm)
            ffmpeg -v error -ss 1 -i "$src" -frames:v 1 -f image2pipe -vcodec png - 2>/dev/null |
                magick png:- -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" -quality 85 "$tmp" ;;
        *)
            magick "${src}[0]" -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" -quality 85 "$tmp" 2>/dev/null ;;
    esac && mv -f "$tmp" "$out" || rm -f "$tmp"
}
export -f _wallthumb_make
export THUMB_SIZE

# ensure_thumbs <fondo>…: crea las que falten o estén desfasadas (avisa si son muchas: la primera vez tarda)
ensure_thumbs() {
    local src out pending=()
    mkdir -p "$THUMB_DIR"
    for src in "$@"; do
        out="$THUMB_DIR/${src//\//#}.jpg"   # = thumb_path, sin subproceso (se llama cientos de veces)
        [[ "$out" -nt "$src" ]] || pending+=("$src" "$out")
    done
    (( ${#pending[@]} )) || return 0
    if (( ${#pending[@]} / 2 > 20 )); then
        notify-send -e -u low -h string:x-canonical-private-synchronous:wallthumbs \
            "Fondos de pantalla" "Preparando $(( ${#pending[@]} / 2 )) miniaturas (solo esta vez)…"
    fi
    printf '%s\0' "${pending[@]}" | xargs -0 -n 2 -P "$(nproc)" bash -c '_wallthumb_make "$1" "$2"' _
}

# labeled_thumb <fondo> <texto> <salida>: miniatura con una etiqueta encima (filas especiales sin nombre visible)
labeled_thumb() {
    local base font
    base=$(thumb_path "$1")
    font=$(fc-match -f '%{file}' 'JetBrains Mono:bold')   # magick necesita la ruta del archivo de fuente
    [[ "$base" -nt "$1" ]] || _wallthumb_make "$1" "$base"   # .wallpaper_current cambia de contenido, no de ruta
    magick "$base" -fill 'rgba(0,0,0,0.55)' -draw "rectangle 0,$(( THUMB_SIZE * 70 / 100 )) $THUMB_SIZE,$THUMB_SIZE" \
        ${font:+-font "$font"} -pointsize $(( THUMB_SIZE / 9 )) -fill white -gravity south \
        -annotate +0+$(( THUMB_SIZE / 14 )) "$2" -quality 85 "$3" 2>/dev/null || cp -f "$base" "$3"
}
