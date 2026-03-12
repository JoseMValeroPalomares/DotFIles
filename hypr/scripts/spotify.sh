#!/bin/bash

# Comprobamos si playerctl está instalado
if ! command -v playerctl &> /dev/null; then
    echo "Falta playerctl"
    exit 1
fi

# Obtenemos el estado de Spotify
STATUS=$(playerctl -p spotify status 2>/dev/null)

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
    # Obtenemos título y artista
    INFO=$(playerctl -p spotify metadata --format '{{title}} - {{artist}}')
    
    # Límite de caracteres (ajusta el 35 si quieres que sea más largo o corto)
    MAX_LEN=35
    
    if [ ${#INFO} -gt $MAX_LEN ]; then
        echo "${INFO:0:$MAX_LEN}..."
    else
        echo "$INFO"
    fi
else
    echo "Nada en reproducción"
fi