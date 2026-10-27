# Progreso

## 2026-10-26
- Fase 1: auditoría de solo lectura del sistema (en la conversación).
- Fase 2: copia de configs reales a `stow/` (enlazadas) y `seeds/` (copiadas si faltan),
  listas de paquetes por componente en `packages/`, ajustes de sistema en `system/`.
  - Excluidos: credenciales de Spotify, historiales, cachés, tokens, `wallpaper_effects`,
    `@girs` de ags, binario y fuentes de wlogout, copias `.bak`.
  - `.zshenv` ahora solo carga `~/.cargo/env` si existe.
- Fase 3: `install.sh` + `lib/` (common, pkg, backup, stow, ui, hardware, components, load),
  post-instaladores en `scripts/post/` (ejecutables también por separado) y perfiles en `hardware/`.
  - Cada componente corre en un subshell con `set -e`: si falla se apunta y se sigue.
  - Probado en un `$HOME` falso: backup de lo que choca, enlaces, semillas y segunda
    ejecución sin cambios. `shellcheck` limpio. Quitado `swaync/backup/` que se había colado.
- Fase 4: README (modos, flags, componentes, dependencias, añadir componente, restaurar backup,
  Spicetify tras actualizar Spotify) y `check-secrets.sh`.
  - Arreglado en check-secrets: con muchos archivos `xargs` parte en tandas y el código de salida
    ocultaba coincidencias; ahora se mira la salida. Probado con un token falso: lo detecta.
  - Validación: `bash -n` (34 scripts), `shellcheck` sin avisos, `stow -n -v` de los 18
    paquetes, `./install.sh --first-time --dry-run` sin errores y sin tocar `~`.

## Pendiente (Jose)
- Subir los wallpapers a un drive y copiarlos a `~/Pictures/wallpapers` tras reinstalar.
- Añadir el remote y hacer push (comandos en el README / conversación).
- Opcional: `sudo pacman -S gitleaks` para un escaneo extra antes de subir.

## 2026-10-27
- Pensado para un Arch vacío: `bootstrap.sh` (git + clone + install.sh), `pacman -Syu` al empezar,
  `system` justo después de `base` (pacman rápido y mirrors antes de descargar el resto).
- `system` añade autologin en tty1 (plantilla con el usuario), locale en_US + es_ES, teclado us
  y zona Europe/Madrid. Perfil intel: `i915` en MODULES. MSI: parámetro de GRUB por defecto «sí».
- Tema: `gsettings` con `dbus-run-session` si no hay sesión (instalación desde TTY).
- Spicetify: si Spotify nunca se abrió (sin `prefs`), lo deja preparado y avisa.
