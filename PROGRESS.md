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
- Prueba en un Arch vacío (contenedor Docker con usuario y sudo): `--minimal` real con paquetes y
  yay, todas las configs con `--no-packages` (sin errores, 2ª ejecución sin backups) y
  `--first-time --dry-run` (todos los paquetes existen). Arreglados por el camino:
  - `theme`: `gsettings` en bus temporal dejaba procesos (gvfs) con la salida abierta y colgaba
    las tuberías; ahora una sola sesión, sin gvfs y con la salida cerrada.
  - `zsh`: `sudo chsh` (no pide contraseña) y `ZSH` explícito para el instalador de OMZ.
  - `systemd-user`: sin gestor de usuario (chroot/contenedor) avisa en vez de fallar.
- Sin rastro del autor original: quitadas las cabeceras en 246 archivos, referencias a su repo y
  wiki, `v2.3.20` y su actualizador; marca «KooL» renombrada (21 archivos y sus referencias,
  p. ej. `Quick_Settings.sh`, `themes/style-N.rasi`, tags `cheat_sheet`/`settings`).
  Verificado: ninguna referencia rota, `bash -n` (74), `luac -p` (43), JSON y Python.
- README por componente (`stow/<c>/README.md`, `seeds/filemanager/README.md`) con captura;
  stow ignora el README de la raíz del paquete y el instalador también. `scripts/capturas.sh`
  genera `docs/capturas/*.png` en un escritorio vacío.
- Capturas en `docs/capturas/` (14): todas las apps salvo Spotify, que va sin captura a propósito.
  Revisadas una a una; datos visibles aceptados por Jose (IP local, foto y ciudad en el bloqueo).

## 2026-10-30
- swaync: iconos generados con la paleta de wallust (`gen-icons.py`, PNG fuera del repo), servicio
  `notifyd` con avisos del sistema y arreglos para los avisos de Zen (detalle en
  `stow/swaync/.config/swaync/PROGRESS.md`). Paso nuevo `scripts/post/swaync.sh`.
- hyprland: icono propio en los avisos que usaban `ja.png` o ninguno, y `WallustSwww.sh` regenera los iconos.
