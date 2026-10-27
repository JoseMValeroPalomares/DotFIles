#!/usr/bin/env bash
# Volumen del altavoz y del micrófono con notificación (teclas multimedia y Waybar)
# Uso: Volume.sh --inc | --dec | --inc-precise | --dec-precise | --toggle |
#                --toggle-mic | --mic-inc | --mic-dec | --get | --get-icon | --get-mic-icon

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"
STEP=5          # paso normal (%)
STEP_PRECISE=1  # paso con ALT
MIC_STEP=5
MAX_VOLUME=150  # límite al subir (permite pasar del 100 %)

# Aplica una acción de pamixer (si se pasa) y lee el estado en la misma llamada.
# pamixer imprime "<silenciado> <volumen>", p. ej. "false 54" → deja $muted y $level
pa() { read -r muted level < <(pamixer "$@" --get-mute --get-volume); }

# Todas las notificaciones de volumen y micrófono se sustituyen entre sí (no se apilan)
# notify <icono> <título> <texto> [nivel para la barra de progreso]
notify() {
    local hints=(-h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true)
    [[ -n "${4:-}" ]] && hints+=(-h "int:value:$4")
    notify-send -e -u low "${hints[@]}" -i "$1" "$2" "$3"
}

is_silent() { [[ "$muted" == true ]] || (( level == 0 )); }

set_volume_icon() {
    if is_silent; then icon="$iDIR/volume-mute.png"
    elif (( level <= 30 )); then icon="$iDIR/volume-low.png"
    elif (( level <= 60 )); then icon="$iDIR/volume-mid.png"
    else icon="$iDIR/volume-high.png"
    fi
}

set_mic_icon() {
    if is_silent; then icon="$iDIR/microphone-mute.png"; else icon="$iDIR/microphone.png"; fi
}

# --- Altavoz ---
notify_volume() {
    set_volume_icon
    if is_silent; then
        notify "$icon" "Volumen" "Silenciado"
    else
        notify "$icon" "Volumen" "$level %" "$level"
        "$sDIR/Sounds.sh" --volume &  # en segundo plano: el sonido dura ~150 ms
    fi
}

toggle_mute() {
    pa -t
    set_volume_icon
    if [[ "$muted" == true ]]; then
        notify "$icon" "Volumen" "Silenciado"
    else
        notify "$icon" "Volumen" "Activado · $level %" "$level"
    fi
}

# change_volume <-i|-d> <paso>; si está silenciado, el primer pulso solo lo reactiva
change_volume() {
    pa
    if [[ "$muted" == true ]]; then
        toggle_mute
        return
    fi
    if [[ "$1" == -i ]]; then
        pa -i "$2" --allow-boost --set-limit "$MAX_VOLUME"
    else
        pa -d "$2"
    fi
    notify_volume
}

# --- Micrófono ---
toggle_mic() {
    pa --default-source -t
    set_mic_icon
    if [[ "$muted" == true ]]; then
        notify "$icon" "Micrófono" "Silenciado"
    else
        notify "$icon" "Micrófono" "Activado · $level %" "$level"
    fi
}

# change_mic <-i|-d>; si está silenciado, el primer pulso solo lo reactiva
change_mic() {
    pa --default-source
    if [[ "$muted" == true ]]; then
        toggle_mic
        return
    fi
    pa --default-source "$1" "$MIC_STEP"
    set_mic_icon
    if is_silent; then
        notify "$icon" "Micrófono" "Silenciado"
    else
        notify "$icon" "Micrófono" "$level %" "$level"
    fi
}

# --- Consultas (salida igual que antes por compatibilidad) ---
print_level() { if is_silent; then echo "Muted"; else echo "$level %"; fi; }

case "$1" in
    --inc)          change_volume -i "$STEP" ;;
    --dec)          change_volume -d "$STEP" ;;
    --inc-precise)  change_volume -i "$STEP_PRECISE" ;;
    --dec-precise)  change_volume -d "$STEP_PRECISE" ;;
    --toggle)       toggle_mute ;;
    --toggle-mic)   toggle_mic ;;
    --mic-inc)      change_mic -i ;;
    --mic-dec)      change_mic -d ;;
    --get-icon)     pa; set_volume_icon; echo "$icon" ;;
    --get-mic-icon) pa --default-source; set_mic_icon; echo "$icon" ;;
    *)              pa; print_level ;;  # --get y sin argumentos
esac
