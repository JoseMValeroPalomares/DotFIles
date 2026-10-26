# Plan de mejora — wlogout (menú de energía, Super + L)

Diagnóstico: 2026-10-20 · wlogout 1.2.2 · Hyprland 0.56.2 con config Lua · 2 monitores 1920×1080 @1

## Qué hay ahora

| Pieza | Ruta | Función |
|---|---|---|
| Atajo | `~/.config/hypr/configs/Keybinds.lua:134` | `Super + L` → `Wlogout.sh` |
| Lanzador | `~/.config/hypr/scripts/Wlogout.sh` | Alterna wlogout y calcula márgenes `-T/-B` según resolución |
| Botones | `~/.config/wlogout/layout` | 6 botones: apagar, reiniciar, suspender, bloquear, cerrar sesión, hibernar |
| Estilo | `~/.config/wlogout/style.css` | Catppuccin Mocha fijo, tarjetas redondeadas, icono PNG normal + PNG hover |
| Iconos | `~/.config/wlogout/icons/` | 16 PNG, 1,1 MB, 512 px (se pintan a ~20 % del botón) |
| Bloqueo | `~/.config/hypr/scripts/LockScreen.sh` → `loginctl lock-session` → hypridle → hyprlock |

## Problemas encontrados

### Fallos (no funcionan o funcionan mal)

1. **Cerrar sesión está roto.** `hyprctl dispatch exit 0` es sintaxis antigua. Con la config Lua,
   `hyprctl dispatch` espera una expresión Lua (ver `~/.config/hypr/PLAN.md`). Lo correcto es
   `hyprctl dispatch 'hl.dsp.exit()'`.
2. **Hibernar no puede funcionar.** El único swap es `zram0`, que vive en la RAM, y el kernel no
   tiene `resume=`. Al pulsar el botón falla, o la sesión se pierde.
3. **Bloquear tarda.** `LockScreen.sh` ejecuta `WeatherWrap.sh` *antes* de bloquear, y ese script
   hace `ping` + `curl` con varios segundos de timeout. Sin red, el bloqueo puede tardar más de 5 s.
4. **CSS inválido.** En `margin: 50 35px;` falta la unidad en `50`. GTK puede ignorar la regla
   entera y avisar en stderr.
5. **Márgenes asimétricos a 1080p.** En el script, `T=200` y `B=100` descentran la rejilla en
   vertical.

### Rendimiento

6. El script llama dos veces a `hyprctl -j monitors | jq`, luego a `awk` dos veces más, y tiene
   cinco ramas casi idénticas. Se pueden ahorrar unos 4 procesos por apertura.
7. Hay 12 PNG para pintar 6 iconos (un normal y un hover por botón), a 512 px para un tamaño final
   de ~70 px. Además sobran 4 archivos sin uso: `hibernate-hover1.png`, `moon_865813.png`,
   `sleep2.png` y `Other icons/` (2634×844).
8. `pgrep` + `pkill` + lanzamiento en dos pasos deja una pequeña condición de carrera si se pulsa
   el atajo dos veces seguidas.

### Diseño y accesibilidad

9. Los colores están fijos, pero el resto del escritorio usa wallust (waybar, rofi, swaync, kitty…).
   wlogout es la única pieza que no cambia con el fondo de pantalla.
10. Hover y foco tienen el mismo aspecto, así que con teclado y ratón a la vez no se sabe qué
    botón está activo.
11. Los botones peligrosos (apagar, reiniciar) se ven igual que bloquear. No hay jerarquía ni
    confirmación.
12. El orden no sigue la frecuencia de uso: lo más habitual (bloquear, suspender) no va primero.
    Como la navegación con teclado sigue ese orden, lo más usado debería quedar más a mano.
13. Los textos están en inglés, mientras que el resto de tu config está en español.
14. Las teclas rápidas (`l`, `s`, `r`…) existen, pero no se ven en ningún sitio.
15. No hay animación de entrada ni desenfoque del fondo. Ambas cosas se resuelven con reglas de
    capa de Hyprland (namespace `logout_dialog`) sin coste para wlogout.

### Fuera de wlogout, pero relacionado

16. `hypridle.conf` usa `hyprctl dispatch dpms on/off` (sintaxis antigua, ya anotado en el plan
    de hypr), y su comentario dice que Super + L bloquea.
17. `KeyHints.sh:56` anuncia `CTRL ALT P` como menú de energía; hay que comprobar que ese atajo
    exista en `Keybinds.lua`.

## Decisiones (tomadas el 2026-10-20)

- D1 → **(a)** quitar hibernar. D2 → **(a)** sin confirmaciones ni diálogos. D3 → **wallust + toques Catppuccin**.
- Desenfoque: descartado. `decoration.blur.enabled = false` en todo Hyprland (decisión previa del usuario), así que el CSS oscurece más el fondo.

### Planteamiento original

- **D1 Hibernar:** (a) quitar el botón (recomendado: 5 botones en una sola fila), o (b) crear un
  swapfile en disco + `resume=` en el kernel (toca `/etc` y el arranque, así que va fuera de este
  proyecto).
- **D2 Confirmación** para apagar y reiniciar: (a) ninguna, como ahora, (b) un segundo diálogo
  mínimo (rofi/yad), o (c) pulsar dos veces el mismo botón en menos de 2 s (recomendado: rápido y
  sin ventana extra).
- **D3 Colores:** (a) dinámicos con wallust (recomendado), o (b) Catppuccin fijo, retocado.

## Fases

### Fase 0 — Base y seguridad
- [ ] Copia de seguridad: `cp -a ~/.config/wlogout ~/.config/wlogout.bak-2026-10-20`, y lo mismo
      con `Wlogout.sh` y `LockScreen.sh`.
- [ ] `git init` en `~/.config/wlogout` (los scripts de hypr se versionan donde ya estén).
- [ ] Medir la situación de partida:
      - captura con `grim` de cada monitor;
      - tiempo hasta que aparece el menú: `hyperfine` sobre el script con `-l` de prueba y cierre
        automático;
      - avisos de GTK: `wlogout 2>&1 | grep -i warn`.
- [ ] Crear `layout.test`, con las mismas teclas pero cada acción cambiada por
      `notify-send "<acción>"`. Así se prueba todo sin apagar nada.

### Fase 1 — Arreglar lo que está roto
- [ ] Cerrar sesión → `hyprctl dispatch 'hl.dsp.exit()'` (probar solo con `layout.test`, que no
      llega a ejecutarlo; la prueba real la haces tú).
- [ ] Hibernar → según D1.
- [ ] `LockScreen.sh`: lanzar el refresco del tiempo en segundo plano (`... &disown`) *después* de
      `loginctl lock-session`. Objetivo: bloqueo en menos de 300 ms.
- [ ] CSS: `margin: 50px 35px;` y comprobar que no queden avisos de GTK.
- [ ] Márgenes simétricos.

### Fase 2 — Optimizar el lanzador
Reescribir `Wlogout.sh` (~20 líneas):
- [ ] Alternar de forma atómica: `pkill -x wlogout && exit 0`.
- [ ] Una sola llamada: `hyprctl -j monitors` → `jq` que devuelva directamente altura y escala del
      monitor con foco. Cálculo en bash, sin `awk`.
- [ ] Márgenes proporcionales a la altura (p. ej. 28 % arriba y abajo) en vez de cinco ramas
      fijas; vale para cualquier resolución.
- [ ] `exec wlogout ...` para no dejar un bash colgado.
- [ ] Botones por fila (`-b`) según D1: 5 en una fila, o 3×2.
- [ ] Comparar tiempos con `hyperfine` frente a la fase 0.

### Fase 3 — Optimizar los recursos
- [ ] Borrar los 4 archivos sin uso, previa confirmación.
- [ ] Cambiar los 12 PNG por 6 SVG simbólicos y recolorearlos con `-gtk-recolor(url(...))` desde el
      CSS. El color de hover sale del propio CSS, así que no hacen falta iconos «-hover». Si GTK3 no
      lo aplica bien a `background-image`, plan B: PNG de 128 px optimizados con `oxipng`.
- [ ] Objetivo: carpeta `icons/` de menos de 30 KB.

### Fase 4 — Diseño
- [ ] Plantilla `~/.config/wallust/templates/colors-wlogout.css` + entrada en `wallust.toml`;
      `style.css` la carga con `@import`. Paleta fija de respaldo si el archivo no existe (D3).
- [ ] Orden por uso: Bloquear · Suspender · Cerrar sesión · Reiniciar · Apagar.
- [ ] Textos en español, con la tecla visible: «Bloquear (L)», «Suspender (U)»…
- [ ] Estados separados:
      - `:hover`: fondo con el color de acento;
      - `:focus`: borde de 3 px con contraste ≥ 3:1 (AA para componentes);
      - foco + hover a la vez: los dos.
- [ ] Jerarquía: apagar y reiniciar con acento rojo o naranja en hover; el resto con el acento
      general.
- [ ] Texto ≥ 4,5:1 sobre el fondo del botón en todos los estados. Lo comprobaré con un script
      sobre los colores que genere wallust, porque cambian con cada fondo.
- [ ] Ajuste fino: `transition` de 150 ms ease-out solo en color, fondo y borde (GTK3 no anima
      `transform`); radio y espaciado coherentes con waybar y rofi.

### Fase 5 — Integración con Hyprland
- [ ] Reglas de capa en Lua para `logout_dialog`: `blur`, `ignore_alpha` y animación `fade` o
      `popin`. Validarlas contra `hl.meta.lua` antes de aplicarlas.
- [x] Confirmación: no se hace (D2).
- [ ] Corregir el comentario de `hypridle.conf` y revisar el atajo de `KeyHints.sh`.

### Fase 6 — Verificación final
- [ ] Probar con `layout.test` todas las teclas y el ratón en los dos monitores.
- [ ] Capturas con `grim` antes y después, en eDP-1 y HDMI-A-1.
- [ ] Cero avisos de GTK en stderr.
- [ ] Tiempos de apertura y de bloqueo frente a la fase 0.
- [ ] Que tú pruebes de verdad: bloquear, suspender y cerrar sesión. Apagar y reiniciar los
      pruebas tú cuando te venga bien.

## Criterios de terminado
- Los 5 (o 6) botones hacen lo que dicen.
- El menú se abre más rápido que ahora (medido) y el bloqueo tarda menos de 300 ms.
- `icons/` ocupa menos de 30 KB y no quedan archivos huérfanos.
- Los colores siguen al fondo de pantalla, con contraste AA en todos los estados.
- Se puede usar entero con teclado, y el foco siempre se distingue.
