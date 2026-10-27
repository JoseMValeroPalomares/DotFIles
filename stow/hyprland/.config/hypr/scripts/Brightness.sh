#!/usr/bin/env bash
# Brillo de la pantalla del portátil con brightnessctl (teclas de brillo y rueda en Waybar)
# Uso: Brightness.sh --inc | --dec | --get

iDIR="$HOME/.config/swaync/icons"
step=10     # paso (%)
min=5       # mínimo (%): a 0 la pantalla se queda negra
max=100

# brightnessctl -m: "intel_backlight,backlight,35520,37%,96000" → porcentaje sin el %
read_percent() { IFS=, read -r _ _ _ percent _ < <(brightnessctl -m "$@"); percent=${percent%\%}; }

change_brightness() {
    local new
    read_percent
    new=$(( percent + $1 ))
    (( new < min )) && new=$min
    (( new > max )) && new=$max
    read_percent set "${new}%"   # aplica y devuelve el valor real

    # Icono redondeado a la veintena superior (20, 40… 100)
    local level=$(( (percent + 19) / 20 * 20 ))
    (( level < 20 )) && level=20
    (( level > 100 )) && level=100

    notify-send -e -u low \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h boolean:SWAYNC_BYPASS_DND:true \
        -h int:value:"$percent" \
        -i "$iDIR/brightness-${level}.png" \
        "Brillo" "$percent %"
}

case "$1" in
    --inc) change_brightness "$step" ;;
    --dec) change_brightness "-$step" ;;
    *)     read_percent; echo "$percent" ;;  # --get y sin argumentos
esac
