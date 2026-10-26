# Plan: dotfiles de Jose (Arch + Hyprland)

## Objetivo
Repo de dotfiles con la configuración real del portátil (MSI Katana GF66, Intel + NVIDIA)
y un `install.sh` modular e idempotente con tres modos: completo (`--first-time`),
personalizado (`--custom`) y mínimo (`--minimal`).

## Decisiones
- GNU Stow con `--no-folding`: un paquete por componente en `stow/<componente>`; se
  enlazan archivos, no carpetas, para que lo que generan las apps en tiempo de ejecución
  no acabe dentro del repo.
- `seeds/<componente>`: archivos que las apps reescriben solas (wallust, Thunar, qt5ct,
  nwg-look, monitores...). Se copian solo si no existen; nunca se enlazan.
- Sin wallpapers en el repo: el script crea `~/Pictures/wallpapers` y los subes tú a un drive.
- Iconos: bessurf y `.icons/default` van en el repo; Flat-Remix y Bibata se instalan desde AUR.
- Temas de Spicetify y plugins de Oh My Zsh se clonan al instalar (no se versionan).
- Datos personales incluidos (coordenadas, fotos de perfil, rutas a proyectos).
- Fuera siempre: credenciales de Spotify, historiales, cachés, tokens
  (`~/token`, `~/.config/panel-maestro/token`, `~/.config/stellar/identity`, `pulse/cookie`),
  `.ssh`, `.gnupg`, navegador (zen), globalStorage/workspaceStorage/History de Code.
- Super+L se queda como está (wlogout); el bloqueo es Ctrl+Alt+L.
- Sin `git push` ni remotos: lo sube Jose.

## Fases
- [x] 1. Auditoría (hecha en conversación)
- [x] 2. Estructura del repo y copia de configs
- [x] 3. `install.sh`, `lib/`, `scripts/`, `hardware/`
- [x] 4. README, `check-secrets.sh` y validación (bash -n, shellcheck, stow -n, --dry-run)
