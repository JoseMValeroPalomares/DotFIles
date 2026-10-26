# Progreso

## 2026-10-26
- Fase 1: auditoría de solo lectura del sistema (en la conversación).
- Fase 2: copia de configs reales a `stow/` (enlazadas) y `seeds/` (copiadas si faltan),
  listas de paquetes por componente en `packages/`, ajustes de sistema en `system/`.
  - Excluidos: credenciales de Spotify, historiales, cachés, tokens, `wallpaper_effects`,
    `@girs` de ags, binario y fuentes de wlogout, copias `.bak`.
  - `.zshenv` ahora solo carga `~/.cargo/env` si existe.
