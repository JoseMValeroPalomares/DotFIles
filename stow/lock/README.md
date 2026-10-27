# Bloqueo (hyprlock + hypridle)

![Bloqueo (hyprlock + hypridle)](../../docs/capturas/lock.png)

Pantalla de bloqueo con reloj, clima, estadísticas y foto de perfil; hypridle bloquea y apaga la pantalla por inactividad.

## Qué incluye

- `hyprlock.conf`: diseño de la pantalla de bloqueo (colores de wallust).
- `hypridle.conf`: bloquea a los 4,5 min y apaga la pantalla a los 5,5 min; no suspende.
- `scripts/LockScreen.sh`, `HyprlockMonitor.sh`, `HyprlockCheck.sh`, `Hypridle.sh` (botón de Waybar).
- `UserScripts/HyprlockBackground.sh` (fondo: actual, aleatorio o fijo) y `HyprlockStats.sh`.
- `profile-lock.png`: foto de la pantalla de bloqueo.

## Atajos

- Ctrl+Alt+L: bloquear
- Super+Ctrl+U: cambiar el fondo del bloqueo
- Super+L → «Bloquear» (wlogout)

## Instalar solo esto

```bash
./install.sh --only lock
```

Funciona mejor junto a: hyprland, wallust. Sin ellos no falla nada, solo deja de responder lo que dependa de ellos.

[← Volver al README principal](../../README.md)
