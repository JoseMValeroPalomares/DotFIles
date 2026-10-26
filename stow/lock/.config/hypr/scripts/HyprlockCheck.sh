#!/usr/bin/env bash
# Comprueba hyprlock.conf SIN bloquear la sesión (útil tras actualizar hyprlock).
# Truco: hyprlock lee y valida la config antes de conectarse; con un display inexistente sale ahí.
#   HyprlockCheck.sh [config]   → código 0 si no hay errores

conf="${1:-$HOME/.config/hypr/hyprlock.conf}"

# hyprlock aborta al no encontrar el display: sin volcado de memoria
ulimit -c 0

echo "$(hyprlock --version 2>&1 | head -1)"
out=$(timeout 5 hyprlock -v -c "$conf" --display hyprlock-check-noexiste 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
errors=$(grep -E "^(ERR|WARN) |Config error" <<<"$out")

# Recursos que la config necesita
missing=()
for f in "$HOME/.cache/hyprlock/background" "$HOME/.cache/hyprlock/colors.conf" \
  "$HOME/.config/hypr/wallust/wallust-hyprlock.conf" "$HOME/.config/hypr/profile-lock.png"; do
  [[ -e "$f" ]] || missing+=("$f")
done
for s in "$HOME/.config/hypr/UserScripts/HyprlockBackground.sh" "$HOME/.config/hypr/UserScripts/HyprlockStats.sh" \
  "$HOME/.config/hypr/scripts/spotify.sh"; do
  [[ -x "$s" ]] || missing+=("$s (no ejecutable)")
done

if [[ -z "$errors" && ${#missing[@]} -eq 0 ]]; then
  echo "OK: config sin errores y todos los recursos presentes"
  exit 0
fi
[[ -n "$errors" ]] && printf 'Errores de configuración:\n%s\n' "$errors"
((${#missing[@]})) && printf 'Falta: %s\n' "${missing[@]}"
exit 1
