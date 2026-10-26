#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Capturas de pantalla con grim (slurp para elegir zona, swappy para editar)
# Uso: ScreenShot.sh --now | --in5 | --in10 | --area | --active | --win | --swappy

# --- Configuración ---
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
iDIR="$HOME/.config/swaync/icons"
iDoR="$HOME/.config/swaync/images"
sDIR="$HOME/.config/hypr/scripts"
NOTIFY_TIME=10  # segundos que la notificación ofrece «Abrir» y «Borrar»

printf -v time '%(%d-%b_%H-%M-%S)T' -1
file="$dir/Screenshot_${time}_${RANDOM}.png"
TAG=string:x-canonical-private-synchronous:shot-notify

# Notificación con botones; imprime la acción elegida (action1/action2) o nada
# notify_actions <icono> <título> <texto> <botón1> <botón2>
notify_actions() {
    timeout "$NOTIFY_TIME" notify-send -t $(( NOTIFY_TIME * 1000 )) -h "$TAG" -i "$1" \
        -A "action1=$4" -A "action2=$5" "$2" "$3"
}

notify_failed() {
    notify-send -u low -h "$TAG" -i "$iDoR/note.png" "Captura" "No se ha guardado"
    "$sDIR/Sounds.sh" --error &
}

# shoot <archivo> <texto> [geometría]: captura, copia al portapapeles y ofrece abrir o borrar
shoot() {
    local path="$1" label="$2" geometry="${3:-}"
    if grim ${geometry:+-g "$geometry"} "$path" && [[ -s "$path" ]]; then
        wl-copy < "$path"
        "$sDIR/Sounds.sh" --screenshot &
        case "$(notify_actions "$iDIR/picture.png" "Captura guardada" "$label" Abrir Borrar)" in
            action1) xdg-open "$path" >/dev/null 2>&1 & ;;
            action2) rm -f "$path" ;;
        esac
    else
        rm -f "$path"
        notify_failed
    fi
}

countdown() {
    local sec
    for (( sec = $1; sec > 0; sec-- )); do
        notify-send -t 1000 -h "$TAG" -i "$iDIR/timer.png" "Captura" "En $sec s"
        sleep 1
    done
    sleep 1  # que la última notificación desaparezca antes de capturar
}

# Geometría "x,y anchoxalto" y clase de la ventana activa; falla si no hay ventana
active_window() {
    local info
    info=$(hyprctl -j activewindow | jq -r 'select(.at) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])|\(.class)"')
    [[ -n "$info" ]] || return 1
    win_geometry="${info%%|*}"
    win_class="${info#*|}"
    win_class="${win_class//[^[:alnum:]._-]/_}"  # apto para nombre de archivo
}

mkdir -p "$dir"

case "$1" in
    --now)
        shoot "$file" "Pantalla completa"
        ;;
    --in5 | --in10)
        countdown "${1#--in}"
        shoot "$file" "Pantalla completa"
        ;;
    --area)
        geometry=$(slurp) || exit 0  # Esc al elegir = cancelar sin aviso
        shoot "$file" "Zona" "$geometry"
        ;;
    --active)
        active_window || { notify_failed; exit 1; }
        shoot "$dir/Screenshot_${time}_${win_class}.png" "Ventana: $win_class" "$win_geometry"
        ;;
    --win)
        active_window || { notify_failed; exit 1; }
        shoot "$file" "Ventana activa" "$win_geometry"
        ;;
    --swappy)
        # Al portapapeles sin guardar; «Editar» la abre en swappy
        geometry=$(slurp) || exit 0
        tmpfile=$(mktemp --suffix=.png)
        trap 'rm -f "$tmpfile"' EXIT
        if grim -g "$geometry" "$tmpfile" && [[ -s "$tmpfile" ]]; then
            wl-copy < "$tmpfile"
            "$sDIR/Sounds.sh" --screenshot &
            case "$(notify_actions "$iDIR/picture.png" "Captura copiada" "Al portapapeles (sin guardar)" Editar Descartar)" in
                action1) swappy -f "$tmpfile" ;;
            esac
        else
            notify_failed
        fi
        ;;
    *)
        echo "Opciones: --now --in5 --in10 --area --active --win --swappy"
        ;;
esac
