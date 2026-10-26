##################################################################
#                                                                #   
#                                                                #
#                  TAK_0'S Per-Window-Switch                     #
#                                                                #
#                                                                #
#                                                                #
#  Just a little script that I made to switch keyboard layouts   #
#       per-window instead of global switching for the more      #
#                 smooth and comfortable workflow.               #  
#                                                                #
##################################################################
# Distribuciones: input.kb_layout en configs/SystemSettings.lua (separadas por comas, p. ej. "us,es")

MAP_FILE="$HOME/.cache/kb_layout_per_window"
ICON="$HOME/.config/swaync/images/ja.png"
SCRIPT_NAME="$(basename "$0")"

# Ensure map file exists
touch "$MAP_FILE"

# Distribuciones configuradas, preguntadas a Hyprland
kb_layouts=($(hyprctl getoption input:kb_layout -j | jq -r '.str' | tr -d '[:space:]' | tr ',' ' '))
count=${#kb_layouts[@]}

# Con una sola distribución no hay nada que alternar (antes notificaba en cada SHIFT+ALT)
(( count < 2 )) && exit 0

# Get current active window ID
get_win() {
  hyprctl activewindow -j | jq -r '.address // .id'
}

# Get available keyboards
get_keyboards() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

# Save window-specific layout
save_map() {
  local W=$1 L=$2
  grep -v "^${W}:" "$MAP_FILE" > "$MAP_FILE.tmp"
  echo "${W}:${L}" >> "$MAP_FILE.tmp"
  mv "$MAP_FILE.tmp" "$MAP_FILE"
}

# Load layout for window (fallback to default)
load_map() {
  local W=$1
  local E
  E=$(grep "^${W}:" "$MAP_FILE")
  [[ -n "$E" ]] && echo "${E#*:}" || echo "${kb_layouts[0]}"
}

# Switch layout for all keyboards to layout index
do_switch() {
  local IDX=$1
  for kb in $(get_keyboards); do
    hyprctl switchxkblayout "$kb" "$IDX" 2>/dev/null
  done
}

# Toggle layout for current window only
cmd_toggle() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local CUR=$(load_map "$W")
  local i NEXT
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$CUR" ]]; then
      i=$idx
      break
    fi
  done
  NEXT=$(( (i+1) % count ))
  do_switch "$NEXT"
  save_map "$W" "${kb_layouts[NEXT]}"
  notify-send -u low -i "$ICON" "kb_layout: ${kb_layouts[NEXT]}"
}

# Restore layout on focus
cmd_restore() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local LAY=$(load_map "$W")
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$LAY" ]]; then
      do_switch "$idx"
      break
    fi
  done
}

# Listen to focus events and restore window-specific layouts
subscribe() {
  local SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [[ -S "$SOCKET2" ]] || { echo "Error: Hyprland socket not found." >&2; exit 1; }

  socat -u UNIX-CONNECT:"$SOCKET2" - | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

# Ensure only one listener (necesita socat; sin él solo funciona el cambio manual)
if command -v socat >/dev/null && ! pgrep -f "socat -u UNIX-CONNECT:.*socket2" >/dev/null; then
  subscribe --listener &
fi

# CLI
case "$1" in
  toggle|"") cmd_toggle ;;
  *) echo "Usage: $SCRIPT_NAME [toggle]" >&2; exit 1 ;;
esac
