#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Menú Quick Settings (SUPER+SHIFT+E): editar la config Lua real y abrir las utilidades.
# Tema: scripts/QuickSettings.rasi. Terminal y editor: los de UserConfigs/01_UserDefaults.lua.

hypr="$HOME/.config/hypr"
scriptsDir="$hypr/scripts"
iDIR="$HOME/.config/swaync/images"
colors_file="$HOME/.config/rofi/wallust/colors-rofi.rasi"

# Si rofi ya está abierto, se cierra (pulsar el atajo otra vez cierra el menú)
if pidof rofi > /dev/null; then
  pkill -x rofi
  exit 0
fi

# Terminal y editor: se preguntan a Hyprland (globales de 01_UserDefaults.lua)
IFS='|' read -r term edit < <(hyprctl repl 'return tostring(term) .. "|" .. tostring(edit)' 2>/dev/null)
[[ -z "$term" || "$term" == nil ]] && term="kitty"
[[ -z "$edit" || "$edit" == nil ]] && edit="${EDITOR:-nano}"

# Preset de animación activo (ver UserConfigs/UserAnimations.lua)
preset=$(head -n1 "$hypr/UserConfigs/AnimationPreset" 2>/dev/null)
preset=${preset:-macOS}

accent=$(sed -nE 's/^\s*selected-normal-background:\s*(#[0-9A-Fa-f]{6}).*/\1/p' "$colors_file" 2>/dev/null)
accent=${accent:-#89b4fa}

# Entradas: "sección" o "icono|texto|detalle|acción|palabras clave (búsqueda)"
# Acciones: edit:<ruta relativa a ~/.config/hypr>, run:<comando>, app:<programa>
entries=(
  "Tu configuración"
  "󰒓|Programas por defecto|01_UserDefaults.lua|edit:UserConfigs/01_UserDefaults.lua|user defaults terminal editor"
  "󰌌|Atajos de teclado|UserKeybinds.lua|edit:UserConfigs/UserKeybinds.lua|user keybinds"
  "󰆍|Programas al iniciar|Startup_Apps.lua|edit:UserConfigs/Startup_Apps.lua|user startup apps autostart"
  "󰖲|Reglas de ventana|WindowRules.lua|edit:UserConfigs/WindowRules.lua|user window rules"
  "󰒔|Ajustes generales|UserSettings.lua|edit:UserConfigs/UserSettings.lua|user settings"
  "󰏘|Decoración: bordes, sombras, blur|UserDecorations.lua|edit:UserConfigs/UserDecorations.lua|user decorations"
  "󰕹|Animaciones (preset activo)|$preset.lua|edit:animations/$preset.lua|user animations"
  "󰌢|Portátil: touchpad y teclas|Laptops.lua|edit:UserConfigs/Laptops.lua|user laptop settings"
  "󰘓|Variables de entorno|ENVariables.lua|edit:UserConfigs/ENVariables.lua|user env variables"
  "Configuración del sistema"
  "󰌌|Atajos del sistema|configs/Keybinds.lua|edit:configs/Keybinds.lua|system default keybinds"
  "󰆍|Programas al iniciar del sistema|configs/Startup_Apps.lua|edit:configs/Startup_Apps.lua|system default startup apps"
  "󰖲|Reglas de ventana del sistema|configs/WindowRules.lua|edit:configs/WindowRules.lua|system default window rules"
  "󰒓|Ajustes del sistema|configs/SystemSettings.lua|edit:configs/SystemSettings.lua|system default settings"
  "Pantallas"
  "󰍹|Monitores y escritorios|nwg-displays → monitors.lua|run:$scriptsDir/MonitorsConfig.sh|configure monitors workspace rules nwg-displays"
  "Apariencia"
  "󰕹|Elegir animaciones|SUPER+SHIFT+A|run:$scriptsDir/Animations.sh|choose hyprland animations"
  "󰄛|Tema de kitty||run:$scriptsDir/Kitty_themes.sh|choose kitty terminal theme"
  "󰉼|Aspecto de apps GTK|nwg-look|app:nwg-look|gtk settings"
  "󰉼|Aspecto de apps Qt6|qt6ct|app:qt6ct|qt apps settings"
  "󰉼|Aspecto de apps Qt5|qt5ct|app:qt5ct|qt apps settings"
  "Herramientas"
  "󰌌|Buscar atajos|SUPER+SHIFT+K|run:$scriptsDir/KeyBinds.sh|search for keybinds"
  "󰊴|Modo juego / ahorro|SUPER+ALT+G|run:$scriptsDir/GameMode.sh|toggle game mode power saving"
)

escape() { local s=${1//&/\&amp;}; s=${s//</\&lt;}; printf '%s' "${s//>/\&gt;}"; }  # \& : en bash 5.2 un & suelto = texto encontrado

rows() {
  local first=1 e icon label detail action keys
  for e in "${entries[@]}"; do
    if [[ "$e" != *"|"* ]]; then
      # Cabecera de sección: no seleccionable
      (( first )) || printf ' \0nonselectable\x1ftrue\n'
      first=0
      printf '<span foreground="%s" weight="bold">%s</span>\0nonselectable\x1ftrue\n' "$accent" "$(escape "${e^^}")"
      continue
    fi
    IFS='|' read -r icon label detail action keys <<< "$e"
    local text="$icon  $(escape "$label")"
    [[ -n "$detail" ]] && text+="  <span alpha=\"55%\" size=\"small\">$(escape "$detail")</span>"
    printf '%s\0meta\x1f%s\n' "$text" "$keys"
  done
}

# Índice de fila de rofi -> entrada (las cabeceras y separadores también ocupan fila)
row_to_entry=()
first=1
for i in "${!entries[@]}"; do
  if [[ "${entries[$i]}" != *"|"* ]]; then
    (( first )) || row_to_entry+=("-")
    first=0
    row_to_entry+=("-")
  else
    row_to_entry+=("$i")
  fi
done

sel=$(rows | rofi -dmenu -i -markup-rows -no-custom -format i -p "" -selected-row 1 \
  -mesg "<b>Ajustes rápidos</b>  ·  Escribe para filtrar  ·  Esc para cerrar" \
  -config "$scriptsDir/QuickSettings.rasi")
[[ -z "$sel" ]] && exit 0
idx=${row_to_entry[$sel]}
[[ -z "$idx" || "$idx" == "-" ]] && exit 0

IFS='|' read -r _ label _ action _ <<< "${entries[$idx]}"
case "$action" in
  edit:*)
    file="$hypr/${action#edit:}"
    if [[ ! -f "$file" ]]; then
      notify-send -u low -i "$iDIR/error.png" "Ajustes rápidos" "No existe: ${action#edit:}"
      exit 1
    fi
    $term -e $edit "$file"
    ;;
  run:*)
    eval "${action#run:}"
    ;;
  app:*)
    app=${action#app:}
    if ! command -v "$app" &>/dev/null; then
      notify-send -u low -i "$iDIR/error.png" "Ajustes rápidos" "Instala primero $app"
      exit 1
    fi
    "$app"
    ;;
esac
