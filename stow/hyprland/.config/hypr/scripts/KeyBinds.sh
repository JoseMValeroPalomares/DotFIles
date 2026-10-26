#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Menú de atajos (SUPER+SHIFT+K): lee los atajos cargados de verdad con `hyprctl binds`
# (scripts/keybinds_menu.py) y los muestra agrupados con el tema scripts/KeyBinds.rasi.

# kill yad to not interfere with this binds
pkill -x yad || true

# Si rofi ya está abierto, se cierra (pulsar el atajo otra vez cierra el menú)
if pidof rofi > /dev/null; then
  pkill -x rofi
  exit 0
fi

scripts_dir="$HOME/.config/hypr/scripts"
rows=$(python3 -I "$scripts_dir/keybinds_menu.py")
if [[ -z "$rows" ]]; then
  notify-send -u low "Atajos" "No se pudieron leer los atajos de Hyprland"
  exit 1
fi

count=$(printf '%s\n' "$rows" | wc -l)
msg="<b>$count atajos</b>  ·  Escribe para filtrar (p. ej. «captura», «SHIFT», «ventana»)  ·  Esc para cerrar"

printf '%s\n' "$rows" | rofi -dmenu -i -markup-rows -no-custom \
  -p "" -mesg "$msg" -config "$scripts_dir/KeyBinds.rasi" > /dev/null
