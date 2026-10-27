#!/usr/bin/env bash
# Sonidos del sistema (los usan Volume.sh y ScreenShot.sh)
# Uso: Sounds.sh --volume | --screenshot | --error

# --- Configuración ---
theme="freedesktop"    # tema de sonidos (carpeta en ~/.local/share/sounds o /usr/share/sounds)
mute=false             # true = ningún sonido
muteScreenshots=false
muteVolume=false
muteErrors=false

[[ "$mute" == true ]] && exit 0

case "$1" in
    --screenshot) [[ "$muteScreenshots" == true ]] && exit 0; sound="screen-capture" ;;
    --volume)     [[ "$muteVolume" == true ]] && exit 0;      sound="audio-volume-change" ;;
    --error)      [[ "$muteErrors" == true ]] && exit 0;      sound="dialog-error" ;;
    *) echo "Sonidos disponibles: --screenshot, --volume, --error"; exit 0 ;;
esac

userDIR="$HOME/.local/share/sounds"
systemDIR="/usr/share/sounds"

# Carpeta del tema (la del usuario tiene prioridad)
themeDIR="$systemDIR/$theme"
[[ -d "$userDIR/$theme" ]] && themeDIR="$userDIR/$theme"

# Tema del que hereda (línea "Inherits=" de index.theme), sin procesos externos
inherits=""
if [[ -f "$themeDIR/index.theme" ]]; then
    while IFS='=' read -r key value; do
        [[ "${key,,}" == inherits ]] && { inherits="${value%%,*}"; break; }
    done < "$themeDIR/index.theme"
fi

# Primer archivo que exista: tema → tema heredado → freedesktop (usuario y sistema)
shopt -s nullglob
sound_file=""
for dir in "$themeDIR" ${inherits:+"$themeDIR/../$inherits"} "$userDIR/freedesktop" "$systemDIR/freedesktop"; do
    files=("$dir/stereo/$sound".*)
    if (( ${#files[@]} )); then
        sound_file="${files[0]}"
        break
    fi
done

if [[ -z "$sound_file" ]]; then
    echo "Error: no se encuentra el sonido «$sound»." >&2
    exit 1
fi

# Reproducir: PipeWire, si no PulseAudio, si no ALSA
for player in pw-play paplay aplay; do
    command -v "$player" >/dev/null 2>&1 && exec "$player" "$sound_file"
done

echo "Error: no hay reproductor de audio (pw-play/paplay/aplay)." >&2
exit 1
