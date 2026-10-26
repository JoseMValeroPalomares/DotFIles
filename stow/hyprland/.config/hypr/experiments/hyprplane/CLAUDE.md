# Proyecto aparcado: plano infinito en UN solo workspace de Hyprland (hyprplane + parche Lua)

> Contexto para retomar con Claude Code. Responde en español de España, directo, explicando cada paso,
> un cambio cada vez, y **pide confirmación antes de compilar o cargar el plugin**.

## Qué quiere el usuario
Un «escritorio grande» 2D, como el mapa de *The Farmer Was Replaced*: un plano infinito por el que moverse
y dejar ventanas repartidas para volver a ellas. **Solo en un workspace** (el 10, monitor HDMI-A-1); el resto
de workspaces deben seguir siendo normales (dwindle). Le gustó cómo funciona; dijo que «habría que cambiar
algunas cosas y arreglar otras» **sin concretar cuáles**: lo primero al retomar es preguntárselo.

## Estado al aparcarlo (2026-10-24)
- **Desactivado y limpio**: plugin descargado, `hyprland.lua` sin cambios, sin build (`build/` no existe),
  sin atajos. Solo quedan en git estos archivos.
- Funcionaba en vivo en Hyprland **0.56.2** (paquete Arch `hyprland 0.56.2-4`, config **Lua**).
- Reproducible: `setup.sh` clona el commit fijado, aplica el parche y compila; el binario salió idéntico
  byte a byte al probado.

## Archivos
| Archivo | Qué es |
|---|---|
| `hyprplane-lua.patch` | Parche propio (~145 líneas) sobre HarryC913/hyprplane @ `3aa8a1f` |
| `hyprplane.lua` | Experimento: plano en el ws 10, eventos y atajos. Se carga con `hyprctl eval 'dofile(...)'` |
| `setup.sh` | Clona + parche + compila en `build/src` (gitignored) |
| `load.sh` | Carga solo en la sesión actual (llama a `setup.sh` si falta la build) |
| `clean.sh` | Vuelve al estado aparcado (descarga, borra build). `--purge` borra el proyecto entero |

## Cómo retomarlo
1. `hyprctl version`: si ya no es 0.56.2, revisar que el parche y la API (`addLuaFunction`, `State::*`) siguen
   valiendo y avisar antes de forzar nada.
2. Preguntar al usuario qué quiere cambiar/arreglar (ver «Pendiente» como punto de partida).
3. Con su confirmación: `./setup.sh` y `./load.sh`. Probar abriendo ventanas en el 10 (SUPER+0).
4. Para editar el C++: trabajar en `build/src`, recompilar (`cmake --build build/src/build`) y recargar con
   `./clean.sh --keep-build && ./load.sh` (descarga sin borrar la build; load.sh carga la nueva por su hash).
   Al terminar, regenerar el parche: `git -C build/src diff -- CMakeLists.txt src/ > hyprplane-lua.patch`
   (sin `json`/`os`/`sys`, que setup.sh borra del clon).
5. Commits pequeños en el repo de `~/.config/hypr` (PROGRESS.md lleva el historial).

## Integración final (cuando el usuario lo dé por bueno; aún NO hecha)
Una sola línea marcada al final de `~/.config/hypr/hyprland.lua` que cargue el plugin al arrancar y luego
`hyprplane.lua` (que ya se protege con `if not hl.plugin.hyprplane then return end`, porque Hyprland vuelve
a leer la config cuando el plugin ya está dentro). Usar una ruta estable al `.so` (p. ej. copia con hash) y
mantener `clean.sh` capaz de quitar esa línea (ya busca `experiments/hyprplane`). Pedir confirmación antes.

## Atajos actuales (capa SUPER+CTRL+SHIFT, que el usuario tenía libre salvo Print)
| Atajo | Acción |
|---|---|
| botón central + arrastrar (en el 10) | mover el plano |
| SUPER + arrastrar izq./dcho. (del usuario) | mover / redimensionar ventana |
| SUPER+CTRL+SHIFT+flechas | mover el plano con el teclado (300 px) |
| SUPER+CTRL+SHIFT+G | traer todas las ventanas a la vista |
| SUPER+CTRL+SHIFT+1…0 | saltar a la ventana N (números del minimapa) |
| SUPER+CTRL+SHIFT+C | encender/apagar el plano en el workspace actual |
No tocar los atajos del usuario (SUPER+flechas = foco, SUPER+SHIFT+flechas = redimensionar,
SUPER+CTRL+flechas = mover ventana, SUPER+ALT+flechas = intercambiar, SUPER+números = workspaces...).
Revisar los reales con `hyprctl -j binds`.

## Qué hace el parche
1. API Lua `hl.plugin.hyprplane.*`: `enter/leave/toggle/is_canvas/adopt(ws_id)`, `pan(dx,dy)`, `jump(n)`,
   `gather()`. Con config Lua los dispatchers `canvas:*` del original son inalcanzables.
   Compilado contra **Lua 5.5** (la VM de Hyprland; también hay una liblua5.4 enlazada, no usarla).
   Las funciones nunca lanzan errores Lua (longjmp saltaría destructores C++): usan `lua_to*x`.
2. Arrastre y minimapa solo sobre el monitor que muestra un workspace con plano (`cursorOnCanvas()`);
   sin esto se perdían clic central y CTRL+clic en todos los workspaces.
3. `grab_button` por defecto = 0 (solo botón central): CTRL+clic sigue llegando a las apps.
4. `onWindowOpened` y `adoptTiled()` apuntan las ventanas en `m_saved` para que `leave()`/descarga las
   devuelvan al mosaico (el original solo re-tileaba las que había al encender).
5. `PLUGIN_EXIT` usa `leaveAll()` (todos los ws con plano, visibles o no). El original llamaba a
   `toggleAllMonitors()`, que con el plano en un ws oculto ENCENDÍA el plano en los visibles y dejaba
   flotando las ventanas del usuario. **Pasó dos veces durante las pruebas** (ver Trampas).
6. `-fno-gnu-unique` para que `dlopen` pueda descargarlo de verdad.

## Pendiente / ideas (confirmar con el usuario)
- Sin zoom ni vista general: el `scripts/canvas-overview` original usa `hyprctl keyword monitor`, que no
  funciona con config Lua (habría que reescribirlo con `hyprctl eval` o hacer el zoom en el plugin).
- Ventanas nuevas aparecen todas en el centro de la vista y se solapan (`spawn_center`).
- Una ventana sacada del 10 se queda flotando (habría que des-flotarla en `window.move_to_workspace`).
- Opciones del plugin (`plugin:hyprplane:*`) registradas con la API antigua (`addConfigValue`, deprecated):
  no se pueden ajustar desde Lua; migrar a `addConfigValueV2`.
- Ventanas maximizadas/fullscreen no entran al plano (el plugin las salta a propósito).
- Ideas de lo que le gustó de Phantomat (kaolti/phantomat): zoom con lente, buscador de ventanas,
  minimapa clicable. Phantomat se descartó porque sustituye TODOS los workspaces por un solo plano.

## Trampas aprendidas (importante)
- `hyprctl keyword` no funciona con config Lua: usar `hyprctl eval '<lua>'`; leer con `hyprctl repl 'return ...'`.
- `hyprctl reload` recrea la VM de Lua: se pierden binds/eventos del experimento (el plugin sigue cargado).
- Las funciones `hl.plugin.<ns>.*` registradas al cargar un plugin **solo aparecen tras `hyprctl reload`**.
- `dlopen` reutiliza la biblioteca ya cargada desde la misma ruta: cargar siempre desde una ruta con hash
  (lo hace `load.sh`). Una build antigua con gnu-unique quedó residente hasta cerrar sesión.
- `hyprctl plugin unload` necesita la ruta exacta cargada: sacarla de `/proc/$(pidof Hyprland)/maps`.
- Si el ws 10 se queda vacío Hyprland lo destruye: `leave(10)` ya no lo encuentra, pero el id sigue en
  `m_canvasWorkspaces` (por eso al recrearlo sigue siendo plano). Con la build vieja eso hizo que la descarga
  encendiera el plano en los ws 1 y 5.
- Reparación si las ventanas del usuario quedan flotando: `hl.dsp.window.float({action="disable", window="address:0x…"})`;
  si dwindle queda con huecos fantasma, cambiar `general.layout` a master y volver a dwindle (`hyprctl eval`);
  eso quita el fullscreen: restaurarlo con `hl.dsp.window.fullscreen({mode="fullscreen", window=...})`.
- `workspace.created` salta antes de que el ws sea consultable: `hyprplane.lua` también escucha `window.open`.
- Para pruebas sin molestar: `hl.dsp.exec_cmd('kitty --class exp2d -e sleep 300', { workspace = '10 silent', suppress_event = 'maximize' })`
  y cerrar con `pkill -f '^kitty --class exp2d'` (sin `^` mata también al shell que lo ejecuta).
- El repo upstream trae `json`, `os`, `sys` (capturas PostScript de ImageMagick, 4,5 MB cada una): basura.

## Historial de opciones probadas (todas eliminadas sin restos)
- a) Layout `scrolling` nativo: es una tira en una dirección, no un plano 2D.
- b) hyprplane sin parche: compila pero no se puede activar desde config Lua → este proyecto lo arregla.
- Phantomat (kaolti/phantomat): el que más gustó, pero un plano global para todos los workspaces.
- c) hyprscroll2d (Lua puro, rejilla 2D por workspace): descartado por el usuario.
- d) hyprgrid / hyprkool (rejilla de workspaces): no llegó a probarse.

## Reglas del usuario (de su petición original y su CLAUDE.md global)
- Copia de seguridad de `~/.config/hypr` en `~/backups/hypr-<fecha>` antes de cambiar nada (la de este
  trabajo: `~/backups/hypr-2026-10-24_0953`).
- No editar `hyprland.lua` salvo UNA línea marcada y comentable; preferir carga ad-hoc (`hyprctl eval`,
  `hyprctl plugin load`) para que reiniciar sesión deje todo limpio.
- Cada cosa con su script que la revierta TODO; atajos sin choques y documentados.
- Comprobar compatibilidad con la versión de Hyprland y avisar en vez de forzar.
- Mantener PLAN.md / PROGRESS.md de `~/.config/hypr` y commits pequeños.
- Nunca comandos de red destructivos ni tocar archivos fuera del proyecto.
