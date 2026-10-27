#!/usr/bin/env bash
# Tema global de rofi (SUPER+CTRL+R y Ajustes rápidos) con vista previa en vivo:
# Intro = probar el tema en el propio menú · Ctrl+S = aplicar y salir · Esc = cancelar (vuelve el anterior)

# --- Configuración ---
ROFI_THEMES_DIR_CONFIG="$HOME/.config/rofi/themes"
ROFI_THEMES_DIR_LOCAL="$HOME/.local/share/rofi/themes"
ROFI_CONFIG_FILE="$HOME/.config/rofi/config.rasi"
ROFI_THEME_FOR_THIS_SCRIPT="$HOME/.config/rofi/config-rofi-theme.rasi"
IDIR="$HOME/.config/swaync/images"

notify_user() { notify-send -u low -h string:x-canonical-private-synchronous:rofi_theme -i "$1" "$2" "$3"; }

# config.rasi tiene una sola línea: @theme "<ruta>". Se escribe en un temporal y se mueve
# (antes cada vista previa añadía líneas y el archivo acababa con decenas de @theme)
write_theme() {
  local tmp
  tmp=$(mktemp "$ROFI_CONFIG_FILE.XXXXXX") || return 1
  printf '@theme "%s"\n' "$1" > "$tmp" && mv -f "$tmp" "$ROFI_CONFIG_FILE"
}

# Ruta con ~ del tema elegido (primero ~/.config/rofi/themes, luego ~/.local/share)
theme_path() {
  if [[ -f "$ROFI_THEMES_DIR_CONFIG/$1.rasi" ]]; then
    echo "~${ROFI_THEMES_DIR_CONFIG#"$HOME"}/$1.rasi"
  elif [[ -f "$ROFI_THEMES_DIR_LOCAL/$1.rasi" ]]; then
    echo "~${ROFI_THEMES_DIR_LOCAL#"$HOME"}/$1.rasi"
  else
    return 1
  fi
}

if [[ ! -f "$ROFI_CONFIG_FILE" ]]; then
  notify_user "$IDIR/error.png" "Tema de rofi" "No existe $ROFI_CONFIG_FILE"
  exit 1
fi

# Copia del config para volver a él si se cancela o el script se interrumpe
original_config=$(<"$ROFI_CONFIG_FILE")
applied=false
restore() { [[ "$applied" == true ]] || printf '%s\n' "$original_config" > "$ROFI_CONFIG_FILE"; }
trap restore EXIT
trap 'exit 1' TERM INT HUP

shopt -s nullglob
themes=()
for f in "$ROFI_THEMES_DIR_CONFIG"/*.rasi "$ROFI_THEMES_DIR_LOCAL"/*.rasi; do
  f="${f##*/}"
  themes+=("${f%.rasi}")
done
mapfile -t themes < <(printf '%s\n' "${themes[@]}" | sort -V -u)

if (( ${#themes[@]} == 0 )); then
  notify_user "$IDIR/error.png" "Tema de rofi" "No hay temas .rasi en $ROFI_THEMES_DIR_CONFIG"
  exit 1
fi

# Empezar en el tema activo
index=0
if [[ "$original_config" =~ @theme[[:space:]]*\"([^\"]+)\" ]]; then
  active="${BASH_REMATCH[1]##*/}"
  active="${active%.rasi}"
  for i in "${!themes[@]}"; do
    [[ "${themes[i]}" == "$active" ]] && { index=$i; break; }
  done
fi

while true; do
  name="${themes[index]}"
  if ! path=$(theme_path "$name") || ! write_theme "$path"; then
    notify_user "$IDIR/error.png" "Tema de rofi" "No se ha podido probar «$name»"
    exit 1
  fi

  choice=$(printf '%s\n' "${themes[@]}" |
    rofi -dmenu -i -format i -no-custom \
      -p "Tema de rofi" \
      -mesg "Intro: probar · Ctrl+S: aplicar y salir · Esc: cancelar" \
      -config "$ROFI_THEME_FOR_THIS_SCRIPT" \
      -selected-row "$index" \
      -kb-custom-1 "Control+s")

  case $? in
    0)  # Intro: probar otro
      [[ "$choice" =~ ^[0-9]+$ ]] && (( choice < ${#themes[@]} )) && index=$choice
      ;;
    10) # Ctrl+S: aplicar el que se está viendo
      applied=true
      notify_user "$IDIR/ja.png" "Tema de rofi aplicado" "$name"
      exit 0
      ;;
    1)  # Esc
      notify_user "$IDIR/note.png" "Tema de rofi" "Cancelado: se mantiene el tema anterior"
      exit 0
      ;;
    *)
      notify_user "$IDIR/error.png" "Tema de rofi" "rofi terminó de forma inesperada; se mantiene el tema anterior"
      exit 1
      ;;
  esac
done
