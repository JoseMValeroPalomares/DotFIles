#!/usr/bin/env bash
# For Searching via web browsers

if ! command -v jq >/dev/null 2>&1; then
    notify-send -u low -i "$HOME/.config/swaync/images/error.png" "Rofi Search" "jq is required for URL encoding. Please install jq."
    exit 1
fi

# Buscador definido en UserConfigs/01_UserDefaults.lua (searchEngine); {} marca dónde va la búsqueda
Search_Engine=$(hyprctl repl 'return tostring(searchEngine)' 2>/dev/null)
[[ -z "$Search_Engine" || "$Search_Engine" == nil ]] && Search_Engine="https://www.google.com/search?q={}"

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='Se abre en el navegador predeterminado · motor: searchEngine en UserConfigs/01_UserDefaults.lua'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill -x rofi
fi

# Open Rofi and pass the selected query to xdg-open for the configured search engine
query=$(printf '' | rofi -dmenu -config "$rofi_theme" -mesg "$msg")

if [[ -z "$query" ]]; then
    exit 0
fi

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
if [[ "$Search_Engine" == *"{}"* ]]; then
    url="${Search_Engine//\{\}/$encoded_query}"
else
    url="${Search_Engine}${encoded_query}"
fi
xdg-open "$url" >/dev/null 2>&1 &
