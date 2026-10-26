#!/usr/bin/env bash
# Monitores y escritorios con nwg-displays, para la config Lua.
# nwg-displays solo sabe guardar monitors.conf / workspaces.conf (que Hyprland ya no lee):
# al cerrarlo, lo guardado se convierte con hyprconf2lua, se muestra un resumen y, si se acepta,
# se copia el .lua anterior a *.lua.bak, se aplica y se recarga. Si la recarga da errores, se restaura.

hypr="$HOME/.config/hypr"
scriptsDir="$hypr/scripts"
iDIR="$HOME/.config/swaync/images"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

notify() { notify-send -u low -i "$iDIR/$1" "Monitores" "$2"; }

for tool in nwg-displays hyprconf2lua luac; do
  if ! command -v "$tool" &>/dev/null; then
    notify error.png "Falta $tool"
    exit 1
  fi
done

mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
before_mon=$(mtime "$hypr/monitors.conf")
before_ws=$(mtime "$hypr/workspaces.conf")

nwg-displays -m "$hypr/monitors.conf" -w "$hypr/workspaces.conf"

changed=()
[[ $(mtime "$hypr/monitors.conf") != "$before_mon" ]] && changed+=(monitors)
[[ $(mtime "$hypr/workspaces.conf") != "$before_ws" ]] && changed+=(workspaces)
if (( ${#changed[@]} == 0 )); then
  notify ja.png "Sin cambios guardados"
  exit 0
fi

# Convertir y comprobar sintaxis antes de tocar nada (--check solo comprueba, no escribe;
# la comprobación de verdad es la recarga de más abajo, que deshace si hay errores)
for name in "${changed[@]}"; do
  if ! hyprconf2lua --check "$hypr/$name.conf" || ! hyprconf2lua "$hypr/$name.conf" -o "$tmp/$name.lua" \
     || ! luac -p "$tmp/$name.lua"; then
    notify error.png "No se pudo convertir $name.conf; no se ha cambiado nada"
    exit 1
  fi
done

# Resumen legible de lo que se va a aplicar
summary=""
if [[ " ${changed[*]} " == *" monitors "* ]]; then
  while IFS=, read -r name mode pos scale _; do
    [[ -z "$name" ]] && continue
    summary+="${name}: ${mode} en ${pos}, escala ${scale}\n"
  done < <(sed -nE 's/^\s*monitor\s*=\s*//p' "$hypr/monitors.conf")
fi
if [[ " ${changed[*]} " == *" workspaces "* ]]; then
  n=$(grep -cE '^\s*workspace\s*=' "$hypr/workspaces.conf")
  summary+="${n} reglas de escritorio\n"
fi

choice=$(printf '󰄬  Aplicar\n󰜺  Descartar\n' | rofi -dmenu -i -no-custom -p "" \
  -mesg "$(printf '<b>¿Aplicar estos cambios?</b>\n%b' "$summary")" \
  -config "$scriptsDir/QuickSettings.rasi" -theme-str 'listview { lines: 2; } inputbar { enabled: false; }')
if [[ "$choice" != *Aplicar ]]; then
  notify ja.png "Cambios descartados; monitors.lua sin tocar"
  exit 0
fi

for name in "${changed[@]}"; do
  cp "$hypr/$name.lua" "$hypr/$name.lua.bak"
  cp "$tmp/$name.lua" "$hypr/$name.lua"
done
hyprctl reload > /dev/null
sleep 0.5
errors=$(hyprctl configerrors | grep -v '^\s*$')
if [[ -n "$errors" ]]; then
  for name in "${changed[@]}"; do cp "$hypr/$name.lua.bak" "$hypr/$name.lua"; done
  hyprctl reload > /dev/null
  notify error.png "Hyprland dio errores; se ha restaurado la configuración anterior"
  exit 1
fi
notify ja.png "Aplicado (copia anterior en *.lua.bak)"
