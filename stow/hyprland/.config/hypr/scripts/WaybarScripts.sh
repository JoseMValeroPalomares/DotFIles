#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Botones de waybar: terminal y gestor de archivos definidos en UserConfigs/01_UserDefaults.lua
# (se preguntan a Hyprland, que tiene cargadas esas variables)

IFS='|' read -r term files < <(hyprctl repl 'return tostring(term) .. "|" .. tostring(files)' 2>/dev/null)
[[ -z "$term" || "$term" == nil ]] && term="kitty"
[[ "$files" == nil ]] && files=""

# Execute accordingly based on the passed argument
launch_files() {
    if [[ -z "$files" ]]; then
        notify-send -u low -i "$HOME/.config/swaync/images/error.png" "Waybar: files" "Define files en UserConfigs/01_UserDefaults.lua o instala un gestor de archivos."
        return 1
    fi
    eval "$files &"
}

if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    launch_files
else
    echo "Usage: $0 [--btop | --nvtop | --nmtui | --term]"
    echo "--btop       : Open btop in a new term"
    echo "--nvtop      : Open nvtop in a new term"
    echo "--nmtui      : Open nmtui in a new term"
    echo "--term   : Launch a term window"
    echo "--files  : Launch a file manager"
fi