#!/usr/bin/env bash
# Elige el monitor donde se ve hyprlock: el externo (HDMI) si está activo; si no, el del portátil.
# El otro queda en negro. hypridle lo ejecuta justo antes de lanzar hyprlock (lock_cmd).
# Escribe ~/.cache/hyprlock/monitor.conf, que hyprlock.conf lee con `source`.
# Si algo falla no escribe nada útil y hyprlock se ve en todos los monitores (nunca sin campo de contraseña).

out="$HOME/.cache/hyprlock/monitor.conf"
mkdir -p "${out%/*}"

mapfile -t mons < <(timeout 2 hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null)

lock="" other="none"
for m in "${mons[@]}"; do
  [[ "$m" != eDP* ]] && { lock="$m"; break; }
done
if [[ -n "$lock" ]]; then
  for m in "${mons[@]}"; do [[ "$m" == eDP* ]] && other="$m"; done
else
  lock="${mons[0]}" # solo el portátil (o lo que haya)
fi

{
  echo "# Generado por scripts/HyprlockMonitor.sh al bloquear. No editar."
  echo "\$LOCK_MONITOR = $lock"
  echo "\$LOCK_OTHER = $other"
} >"$out.tmp" && mv -f "$out.tmp" "$out"
exit 0
