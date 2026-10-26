# Proyecto: optimización de Code - OSS (Arch + Hyprland)

Esta carpeta (`~/.config/Code - OSS/`) es la configuración de Code - OSS del usuario.
Hay un proyecto en curso para optimizarla **sin perder su aspecto actual**.

## Al iniciar una sesión aquí
1. Lee `PLAN.md` (plan aprobado, decisiones y fases) y `PROGRESS.md` (estado, mediciones, pendientes).
2. Continúa por la **primera fase no completada** de `PROGRESS.md`. Dile al usuario en qué punto estáis y qué vas a hacer en esa fase antes de tocar nada.
3. Trabaja **una fase por mensaje**. Al terminar una fase, para y espera a que el usuario pruebe y te pase resultados.

## Reglas obligatorias
- Responder en español de España, directo, paso a paso, teoría + ejemplo práctico, archivos completos o fragmentos listos para copiar, explicando el porqué de cada cambio.
- **Un cambio cada vez → medir → poder revertir.** Cada cambio = un commit pequeño (una vez exista el repo de la fase 0).
- **Nunca desinstalar extensiones sin confirmación**: primero desactivar. (Excepción ya confirmada: `jeanp413.open-remote-ssh`, ver PLAN.md; aun así, desactivar primero y desinstalar al final de la fase 2.)
- **No borrar archivos** (tampoco `CachedData`) sin permiso explícito en esa sesión.
- **No tocar archivos fuera de esta carpeta** (p. ej. `~/.config/code-flags.conf`, `~/.vscode-oss/`, `~/.config/wallust/`, `/usr/lib/code/product.json`) sin que el usuario lo confirme en ese momento; preferible darle el comando para que lo ejecute él. **Nunca** editar `/usr/lib/code/product.json`.
- Leer (sin modificar) `~/.config/wallust/` y `logs/` está permitido.
- No exponer datos sensibles: al mostrar `settings.json` o `globalStorage`, enmascarar tokens/claves; nunca leer `~/.ssh/`.
- `settings.json` es JSONC (lleva comentarios): editar con Edit, no con `jq`.
- Antes de recomendar una extensión, verificar que existe en Open VSX (`https://open-vsx.org/api/<publisher>/<name>`).
- Actualizar `PROGRESS.md` al terminar cada fase/cambio.
- Las normas globales de webs (playwright, /impeccable) no aplican a este proyecto: no es una web.
