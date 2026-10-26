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
