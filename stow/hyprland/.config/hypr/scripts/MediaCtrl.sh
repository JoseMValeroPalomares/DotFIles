#!/usr/bin/env bash
# Teclas multimedia con playerctl: --nxt | --prv | --pause | --stop

music_icon="$HOME/.config/swaync/icons/music.png"

# Todas las notificaciones de música se sustituyen entre sí (no se apilan)
notify() { notify-send -e -u low -h string:x-canonical-private-synchronous:media -i "$music_icon" "$@"; }

# swaync interpreta marcado: escapar & < > de títulos y artistas
escape() { local s=${1//&/\&amp;}; s=${s//</\&lt;}; printf '%s' "${s//>/\&gt;}"; }  # \& : en bash 5.2 un & suelto = texto encontrado

# Estado, título y artista en una sola llamada a playerctl
show_music_notification() {
    local status title artist
    IFS=$'\t' read -r status title artist < <(
        playerctl metadata --format $'{{status}}\t{{title}}\t{{artist}}' 2>/dev/null
    )
    case "$status" in
        Playing) notify "Reproduciendo" "$(escape "$title")${artist:+ · $(escape "$artist")}" ;;
        Paused)  notify "En pausa" "$(escape "$title")" ;;
    esac
}

case "$1" in
    --nxt)
        playerctl next
        sleep 0.2  # el reproductor tarda un momento en publicar la pista nueva
        show_music_notification
        ;;
    --prv)
        playerctl previous
        sleep 0.2
        show_music_notification
        ;;
    --pause)
        playerctl play-pause
        sleep 0.1
        show_music_notification
        ;;
    --stop)
        playerctl stop
        notify "Reproducción detenida"
        ;;
    *)
        echo "Uso: $0 --nxt | --prv | --pause | --stop"
        exit 1
        ;;
esac
