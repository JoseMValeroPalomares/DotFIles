#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Selector de emojis (SUPER+ALT+E): copia al portapapeles el emoji elegido.
# Se ve solo el emoji; el nombre, las palabras clave y la categoría se buscan igual (van como «meta» invisible).
# Intro = copiar · Shift+Intro = marcar varios (luego Intro los copia juntos)
# Alt+1…Alt+9 = categoría · Alt+0 = todo (recientes primero) · Esc = salir

# --- Configuración ---
rofi_theme="$HOME/.config/rofi/config-emoji.rasi"
emoji_file="$HOME/.config/hypr/scripts/emojis.txt"   # una línea por emoji: "categoría 😀 nombre palabras clave"
recent_file="${XDG_STATE_HOME:-$HOME/.local/state}/rofi-emoji/recientes"
RECENT_MAX=20   # recientes que se muestran primero en «Todo»

# Categorías: identificador del archivo de datos | icono | nombre (Alt+1 = la primera)
CATEGORIES=(
    "caras|😀|Caras"
    "personas|👋|Personas"
    "animales|🐶|Naturaleza"
    "comida|🍔|Comida"
    "viajes|✈️|Viajes"
    "actividades|⚽|Actividades"
    "objetos|💡|Objetos"
    "simbolos|🔣|Símbolos"
    "banderas|🏁|Banderas"
)

pidof rofi >/dev/null && pkill -x rofi

# Filas de rofi: "emoji\0meta\x1fcategoría nombre palabras".
# $1 = categoría (vacío = todas, con los recientes delante)
list() {
    local recent="$recent_file"
    [[ -z "$1" && -s "$recent" ]] || recent=/dev/null
    awk -v want="$1" '
        FILENAME == ARGV[1] { pos[$0] = FNR; n = FNR; next }   # recientes (NR == FNR falla si está vacío)
        want == "" || $1 == want {
            cat = $1; e = $2; $1 = ""; $2 = ""
            row = e "\0meta\037" cat " " substr($0, 3)
            if (e in pos) top[pos[e]] = row; else rest[++m] = row
        }
        END {
            for (i = 1; i <= n; i++) if (i in top) print top[i]
            for (i = 1; i <= m; i++) print rest[i]
        }' "$recent" "$emoji_file"
}

# Barra de categorías del mensaje; la activa en negrita y subrayada
message() {
    local i parts c icon name
    if [[ -z "$1" ]]; then parts="<b><u>0 Todo</u></b>"; else parts="0 Todo"; fi
    for i in "${!CATEGORIES[@]}"; do
        IFS='|' read -r c icon name <<< "${CATEGORIES[i]}"
        if [[ "$c" == "$1" ]]; then
            parts+="   <b><u>$((i + 1)) $icon $name</u></b>"
        else
            parts+="   $((i + 1)) $icon"
        fi
    done
    printf '%s\n%s' "Alt + número: $parts" "Intro: copiar · Shift+Intro: marcar varios · Ctrl+V para pegar"
}

custom_keys=()
for i in {1..9}; do custom_keys+=(-kb-custom-"$i" "Alt+$i"); done
custom_keys+=(-kb-custom-10 "Alt+0")

category=""
while true; do
    selection=$(list "$category" |
        rofi -dmenu -i -multi-select -ballot-unselected-str "" -ballot-selected-str "✓" \
            -mesg "$(message "$category")" -config "$rofi_theme" "${custom_keys[@]}")
    code=$?
    if (( code >= 10 && code <= 18 )); then          # Alt+1…9
        category="${CATEGORIES[code - 10]%%|*}"
    elif (( code == 19 )); then                      # Alt+0
        category=""
    elif (( code == 0 )) && [[ -n "$selection" ]]; then
        break
    else                                             # Esc
        exit 0
    fi
done

# Sin -format: rofi devuelve el texto visible, es decir, el emoji (una línea por cada uno marcado)
emojis="${selection//$'\n'/}"
printf '%s' "$emojis" | wl-copy
notify-send -e -u low -h string:x-canonical-private-synchronous:emoji "$emojis copiado" "Ctrl+V para pegar"

# Guardar recientes: los elegidos primero, sin repetir, como mucho RECENT_MAX
mkdir -p "${recent_file%/*}"
{ printf '%s\n' "$selection"; cat "$recent_file" 2>/dev/null; } |
    awk 'NF && !seen[$0]++' | head -n "$RECENT_MAX" > "$recent_file.tmp" &&
    mv -f "$recent_file.tmp" "$recent_file"
