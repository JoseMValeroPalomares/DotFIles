#!/usr/bin/env bash
# wlogout (menú de energía). Abre o cierra el menú en el monitor con foco.
# WLOGOUT_TEST=1 cambia cada acción por un notify-send, para probar sin apagar nada.

# Si ya está abierto, el atajo lo cierra
pkill -x wlogout && exit 0

layout="$HOME/.config/wlogout/layout"
if [[ $WLOGOUT_TEST == 1 ]]; then
    test_layout="${XDG_RUNTIME_DIR:-/tmp}/wlogout-layout.test"
    awk -F'"' '/"label"/ { l = $4 } /"action"/ { $0 = "    \"action\" : \"notify-send -a wlogout-test " l "\"," } 1' \
        "$layout" > "$test_layout"
    layout=$test_layout
fi

# Altura lógica del monitor con foco; márgenes de 150px arriba y abajo a 1080p, proporcionales en el resto
h=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .height / .scale | floor')
vert=$((${h:-1080} * 150 / 1080))

# wlogout parcheado (flechas con vuelta, sin celda fantasma): ~/.config/wlogout/src/README.md
bin="$HOME/.config/wlogout/bin/wlogout"
[[ -x $bin ]] || bin=wlogout

exec "$bin" --protocol layer-shell --layout "$layout" -b 3 -T "$vert" -B "$vert"
