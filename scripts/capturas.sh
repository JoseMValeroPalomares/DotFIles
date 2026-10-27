#!/usr/bin/env bash
# Hace las capturas del README: abre cada aplicación con tu configuración, la fotografía con grim
# y la cierra. Ejecútalo dentro de tu sesión de Hyprland, con el escritorio despejado.
#   ./scripts/capturas.sh              # todas
#   ./scripts/capturas.sh kitty rofi   # solo algunas
# Las imágenes van a docs/capturas/<nombre>.png. Revísalas antes de hacer commit
# (pueden salir nombres de archivos, notificaciones o datos personales).
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
OUT="$REPO/docs/capturas"
HYPR="$HOME/.config/hypr"
mkdir -p "$OUT"

[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || { echo "Ejecútalo dentro de Hyprland." >&2; exit 1; }
for t in grim jq hyprctl; do command -v "$t" >/dev/null || { echo "Falta $t" >&2; exit 1; }; done

say() { printf '\e[1;35m==>\e[0m %s\n' "$*"; }

monitor_geom() { # geometría del monitor con foco: "x,y wxh"
    hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
}

window_geom() { # window_geom <clase> -> "x,y wxh" de la primera ventana con esa clase
    hyprctl clients -j | jq -r --arg c "$1" \
        'first(.[] | select((.class | ascii_downcase) == ($c | ascii_downcase) or (.initialClass | ascii_downcase) == ($c | ascii_downcase))) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

wait_window() { # wait_window <clase> [segundos]
    local i
    for ((i = 0; i < ${2:-15} * 4; i++)); do
        [[ -n $(window_geom "$1") ]] && { sleep 1; return 0; }
        sleep 0.25
    done
    return 1
}

shot_screen() { grim -g "$(monitor_geom)" "$OUT/$1.png"; echo "    → docs/capturas/$1.png"; }

shot_window() { # shot_window <nombre> <clase>
    local g
    g=$(window_geom "$2")
    if [[ -z $g ]]; then echo "    ! no encontré la ventana $2" >&2; return 1; fi
    grim -g "$g" "$OUT/$1.png"
    echo "    → docs/capturas/$1.png"
}

close_class() { # cierra las ventanas de una clase (por PID: vale para la config en Lua)
    local pid
    for pid in $(hyprctl clients -j | jq -r --arg c "$1" '.[] | select((.class | ascii_downcase) == ($c | ascii_downcase)) | .pid'); do
        kill "$pid" 2>/dev/null || true
    done
    sleep 0.5
}

# Las capturas se hacen en un escritorio vacío para que no salga lo que tengas abierto
ORIG_WS=$(hyprctl activeworkspace -j | jq -r '.id')
goto_ws() { hyprctl dispatch "hl.dsp.focus({ workspace = $1 })" >/dev/null; sleep 0.6; }
trap 'goto_ws "$ORIG_WS"' EXIT
goto_ws '"empty"'
if (($(hyprctl activeworkspace -j | jq -r '.windows') > 0)); then
    echo "No pude cambiar a un escritorio vacío: cancelo para no capturar tus ventanas." >&2
    exit 1
fi

# Abre una app en un kitty propio (clase única) y captura su ventana
kitty_shot() { # kitty_shot <nombre> <comando...>
    local name=$1 class="captura-$1"; shift
    kitty --class "$class" -o initial_window_width=1200 -o initial_window_height=720 "$@" >/dev/null 2>&1 &
    wait_window "$class" && sleep 1.5 && shot_window "$name" "$class"
    close_class "$class"
}

cap_escritorio() { say "Escritorio (Hyprland + Waybar)"; shot_screen hyprland; }

cap_waybar() {
    say "Waybar"
    # Geometría real de la barra (capa "waybar"), esté arriba o abajo, con un pequeño margen
    local g
    g=$(hyprctl layers -j | jq -r 'first(.[] | .levels[] | .[] | select(.namespace == "waybar"))
        | "\(.x - 8 | if . < 0 then 0 else . end),\(.y - 8 | if . < 0 then 0 else . end) \(.w + 16)x\(.h + 16)"')
    [[ -n $g ]] || { echo "    ! waybar no está en marcha" >&2; return 1; }
    grim -g "$g" "$OUT/waybar.png" && echo "    → docs/capturas/waybar.png"
}

cap_swaync() {
    say "SwayNC"
    notify-send -a "dotfiles" "Notificación de ejemplo" "Así se ven las notificaciones con mi tema" || true
    sleep 1
    swaync-client -op >/dev/null; sleep 1.2
    shot_screen swaync
    swaync-client -cp >/dev/null
}

cap_rofi() {
    say "Rofi"
    rofi -show drun >/dev/null 2>&1 &
    sleep 1.2; shot_screen rofi; pkill -x rofi || true
}

cap_wlogout() {
    say "wlogout (Super+L)"
    "$HYPR/scripts/Wlogout.sh" >/dev/null 2>&1 &
    sleep 1.5; shot_screen wlogout; pkill -x wlogout || true
}

cap_quickshell() {
    say "Quickshell (overview, Super+A)"
    "$HYPR/scripts/OverviewToggle.sh" >/dev/null 2>&1 || true
    sleep 1.2; shot_screen quickshell
    "$HYPR/scripts/OverviewToggle.sh" >/dev/null 2>&1 || true
}

cap_kitty() { say "Kitty + Zsh"; kitty_shot kitty zsh -ic 'fastfetch; print; ls --tree --depth 1 ~/dotfiles | head -20; exec zsh -i'; }
cap_zsh() { say "Zsh (prompt y plugins)"; kitty_shot zsh zsh -ic 'cd ~/dotfiles; git log --oneline | head -5; print; exec zsh -i'; }
cap_nano() { say "Nano"; kitty_shot nano nano "$REPO/stow/hyprland/.config/hypr/hyprland.lua"; }
cap_cli() { say "btop (sin lista de procesos)"; kitty_shot cli btop -p 2; }

cap_filemanager() {
    say "Thunar"
    thunar "$HOME/dotfiles" >/dev/null 2>&1 &
    wait_window Thunar && shot_window filemanager Thunar
    close_class Thunar
}

cap_theme() {
    say "Tema GTK (pavucontrol)"
    pavucontrol >/dev/null 2>&1 &
    wait_window org.pulseaudio.pavucontrol && shot_window theme org.pulseaudio.pavucontrol
    close_class org.pulseaudio.pavucontrol
}

cap_code_oss() {
    say "Code - OSS"
    code-oss --new-window "$REPO/install.sh" >/dev/null 2>&1 &
    wait_window code-oss 25 && sleep 3 && shot_window code-oss code-oss
    close_class code-oss
}

cap_spicetify() {
    say "Spotify + Spicetify"
    local was_running=0
    pgrep -x spotify >/dev/null && was_running=1
    ((was_running)) || { spotify >/dev/null 2>&1 & }
    wait_window Spotify 30 && sleep 4 && shot_window spicetify Spotify
    ((was_running)) || close_class Spotify
}

cap_lock() {
    say "Hyprlock: se bloqueará la pantalla; la captura se hace sola y luego desbloqueas tú"
    if [[ -t 0 ]]; then
        read -r -p "    Enter para bloquear (o escribe n para saltar): " a
        [[ $a == n ]] && return 0
    elif ((LOCK_EXPLICIT)); then
        # Sin terminal (p. ej. «! comando» en Claude Code): pedido a propósito, aviso y cuenta atrás
        notify-send -a dotfiles "Captura del bloqueo" "La pantalla se bloquea en 5 s; desbloquea con tu contraseña" || true
        local i
        for i in 5 4 3 2 1; do printf '    bloqueo en %s…\r' "$i"; sleep 1; done; echo
    else
        echo "    (se salta en la tanda completa sin terminal; hazla aparte: ./scripts/capturas.sh lock)"
        return 0
    fi
    pidof hyprlock >/dev/null && { echo "    ! hyprlock ya está en marcha" >&2; return 1; }
    ( sleep 3; grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" "$OUT/lock.png" ) &
    hyprlock
    wait
    if [[ -s $OUT/lock.png ]]; then echo "    → docs/capturas/lock.png"; else echo "    ! no se pudo capturar el bloqueo" >&2; fi
}

ALL=(escritorio waybar swaync rofi wlogout quickshell kitty zsh nano cli filemanager theme code_oss spicetify lock)
LOCK_EXPLICIT=0
(($#)) && ALL=("$@")
[[ " $* " == *" lock "* ]] && LOCK_EXPLICIT=1
for c in "${ALL[@]}"; do
    c=${c//-/_}
    if declare -F "cap_$c" >/dev/null; then
        "cap_$c" || echo "    ! falló la captura de $c" >&2
        sleep 0.5
    else
        echo "Captura desconocida: $c (disponibles: escritorio waybar swaync rofi wlogout quickshell kitty zsh nano cli filemanager theme code-oss spicetify lock)" >&2
    fi
done
say "Hecho. Revisa docs/capturas/ antes de hacer commit."
