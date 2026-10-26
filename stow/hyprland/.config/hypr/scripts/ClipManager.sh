#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager. This script uses cliphist, rofi, and wl-copy.

# Variables
rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
msg='Ctrl+Supr  borrar entrada     Alt+Supr  vaciar historial'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill -x rofi
fi

while true; do
    result=$(
        rofi -i -dmenu \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -display-columns 2 -display-column-separator $'\t' \
            -config $rofi_theme < <(cliphist list) \
			-mesg "$msg" 
    )

    case "$?" in
        1)
            exit
            ;;
        0)
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    cliphist decode <<<"$result" | wl-copy
                    exit
                    ;;
            esac
            ;;
        10)
            cliphist delete <<<"$result"
            ;;
        11)
            cliphist wipe
            ;;
        *)
            # rofi cerrado por señal (p. ej. el pkill de arriba al volver a pulsar SUPER+V):
            # sin esto el bucle lo relanzaba y quedaban scripts colgados
            exit
            ;;
    esac
done

