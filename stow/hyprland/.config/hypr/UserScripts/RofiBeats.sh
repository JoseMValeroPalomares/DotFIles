#!/usr/bin/env bash
# RofiBeats (SUPER+H): música local o emisoras en línea con mpv, y gestión de la lista de emisoras

mDIR="$HOME/Music/"
iDIR="$HOME/.config/swaync/icons"
rofi_theme="$HOME/.config/rofi/config-rofi-Beats.rasi"            # listas
rofi_theme_menu="$HOME/.config/rofi/config-rofi-Beats-menu.rasi"  # menú principal
music_list="$HOME/.config/rofi/online_music.list"   # una emisora por línea: "Nombre|URL"
now_file="${XDG_RUNTIME_DIR:-/tmp}/rofibeats-now"   # qué está sonando (para el menú)

# El mpv de RofiBeats lleva este título: así «Detener» solo para su música, no otros vídeos con mpv
MPV_TAG="--title=RofiBeats"

# Iconos Nerd Font (Material Design)
I_RADIO=$'\U000F0439' I_HEAD=$'\U000F02CB' I_YT=$'\U000F05C3' I_MUSIC=$'\U000F075A' I_NOTE=$'\U000F0388'
I_SHUFFLE=$'\U000F049D' I_STOP=$'\U000F04DB' I_COG=$'\U000F0493' I_PLUS=$'\U000F0415' I_DEL=$'\U000F01B4' I_PLAY=$'\U000F040A'

mkdir -p "${music_list%/*}"
[[ -f "$music_list" ]] || touch "$music_list"

notification() { notify-send -e -u low -h string:x-canonical-private-synchronous:rofibeats -i "$iDIR/music.png" "$@"; }

# swaync y las filas de rofi usan marcado: escapar & < > (\& porque en bash 5.2 & = texto encontrado)
escape() { local s=${1//&/\&amp;}; s=${s//</\&lt;}; printf '%s' "${s//>/\&gt;}"; }

# Texto pequeño y tenue a la derecha de una fila
dim() { printf '  <span alpha="50%%" size="small">%s</span>' "$(escape "$1")"; }

music_playing() { pgrep -f -- "^mpv $MPV_TAG" >/dev/null; }

stop_music() {
    if music_playing; then
        pkill -f -- "^mpv $MPV_TAG"
        rm -f "$now_file"
        notification "RofiBeats" "Música detenida"
    fi
}

# play <nombre para mostrar> <argumentos de mpv…>
play() {
    local name="$1"; shift
    stop_music
    printf '%s\n' "$name" > "$now_file"
    notification "Reproduciendo" "$(escape "$name")"
    mpv "$MPV_TAG" --no-video "$@"
    # Solo borrar el aviso si sigue siendo el nuestro (otra canción pudo sustituirla)
    [[ "$(cat "$now_file" 2>/dev/null)" == "$name" ]] && ! music_playing && rm -f "$now_file"
}

# pick <tema> <ayuda> [mensaje]: filas con marcado por stdin → número de fila elegida
pick() {
    rofi -dmenu -i -markup-rows -no-custom -format i -config "$1" \
        -theme-str "entry { placeholder: \"$2\"; }" ${3:+-mesg "$3"}
}

# ask <ayuda>: pide un texto
ask() { rofi -dmenu -lines 0 -config "$rofi_theme_menu" -theme-str "entry { placeholder: \"$1\"; }" < /dev/null; }

# --- Emisoras: "FM - Easy Rock 96.3 📻🎶" → icono de radio + "Easy Rock 96.3" + «FM» pequeño ---
mapfile -t stations < <(grep -v '^[[:space:]]*$' "$music_list" | sort)
# Nombres sin los emojis del final, en una sola pasada (mismo orden que stations)
mapfile -t clean_names < <(printf '%s\n' "${stations[@]%%|*}" | sed -E 's/[[:space:]]*[^[:alnum:][:space:]().,&+-]+$//')

# Nombre visible y tipo («FM», «Radio», «YT»…) de cada emisora, calculados una vez en bash
names=() types=()
for name in "${clean_names[@]}"; do
    type=""
    [[ "$name" =~ ^([[:alnum:]]+)[[:space:]]+-[[:space:]]+(.+)$ ]] && { type="${BASH_REMATCH[1]}"; name="${BASH_REMATCH[2]}"; }
    names+=("$name") types+=("$type")
done

station_rows() {
    local i icon
    for i in "${!names[@]}"; do
        case "${types[i]^^}" in
            FM)    icon="$I_RADIO" ;;
            RADIO) icon="$I_HEAD" ;;
            YT)    icon="$I_YT" ;;
            *)     icon="$I_MUSIC" ;;
        esac
        printf '%s   %s%s\n' "$icon" "$(escape "${names[i]}")" "${types[i]:+$(dim "${types[i]}")}"
    done
}

play_online_music() {
    if (( ${#stations[@]} == 0 )); then
        notification "RofiBeats" "No hay emisoras: añade alguna en «Gestionar emisoras»"
        return 0
    fi
    local row line
    row=$(station_rows | pick "$rofi_theme" "Elegir emisora")
    [[ "$row" =~ ^[0-9]+$ ]] || return 0
    line="${stations[row]}"
    play "${names[row]}" --shuffle "${line#*|}"
}

# --- Música local ---
mapfile -t files < <(find -L "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" \
    -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.m4a" -o -iname "*.mp4" \) 2>/dev/null | sort)

play_local_music() {
    local f rel row name
    row=$(for f in "${files[@]}"; do
        rel="${f#"$mDIR"}"; name="${rel##*/}"
        printf '%s   %s%s\n' "$I_NOTE" "$(escape "${name%.*}")" "$([[ "$rel" == */* ]] && dim "${rel%/*}")"
    done | pick "$rofi_theme" "Elegir canción")
    [[ "$row" =~ ^[0-9]+$ ]] || return 0
    name="${files[row]##*/}"
    play "${name%.*}" --playlist-start="$row" --loop-playlist "${files[@]}"
}

# --- Gestión de emisoras ---
manage_music() {
    local row name url line
    row=$(printf '%s\n' "$I_PLUS   Añadir emisora" "$I_DEL   Quitar emisora" | pick "$rofi_theme_menu" "Gestionar emisoras")
    case "$row" in
        0)
            name=$(ask "Nombre de la emisora"); [[ -n "$name" ]] || return
            url=$(ask "URL (stream o YouTube)"); [[ -n "$url" ]] || return
            printf '%s|%s\n' "${name//|/-}" "$url" >> "$music_list"
            notification "Emisora añadida" "$(escape "$name")"
            ;;
        1)
            row=$(station_rows | pick "$rofi_theme" "Emisora que quitar")
            [[ "$row" =~ ^[0-9]+$ ]] || return
            line="${stations[row]}"
            # Línea exacta (antes quitar «Lofi» quitaba también «Lofi Girl»)
            awk -v l="$line" '$0 != l' "$music_list" > "$music_list.tmp" && mv -f "$music_list.tmp" "$music_list"
            notification "Emisora quitada" "$(escape "${line%%|*}")"
            ;;
    esac
}

# --- Menú principal: solo las opciones que tienen sentido ahora ---
pidof rofi >/dev/null && pkill -x rofi

labels=() actions=()
add() { labels+=("$1"); actions+=("$2"); }
add "$I_RADIO   Emisoras en línea$(dim "${#stations[@]}")" online
if (( ${#files[@]} )); then
    add "$I_NOTE   Música local$(dim "${#files[@]}")" local
    add "$I_SHUFFLE   Música local en aleatorio" shuffle
fi
music_playing && add "$I_STOP   Detener" stop
add "$I_COG   Gestionar emisoras" manage

if music_playing; then
    status="$I_PLAY  <b>Sonando:</b> $(escape "$(cat "$now_file" 2>/dev/null || echo "música")")"
else
    status="Nada sonando"
fi

row=$(printf '%s\n' "${labels[@]}" | pick "$rofi_theme_menu" "RofiBeats" "$status")
[[ "$row" =~ ^[0-9]+$ ]] || exit 0

case "${actions[row]}" in
    online)  play_online_music ;;
    local)   play_local_music ;;
    shuffle) play "Música local en aleatorio" --shuffle --loop-playlist "$mDIR" ;;
    stop)    stop_music ;;
    manage)  manage_music ;;
esac
