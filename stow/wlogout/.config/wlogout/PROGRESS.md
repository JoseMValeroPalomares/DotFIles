# Progreso — wlogout

## 2026-10-20 — Sesión 1: diagnóstico
- [x] Revisados `layout`, `style.css`, `icons/`, `Wlogout.sh`, `LockScreen.sh`, `hypridle.conf`.
- [x] Escrito `PLAN.md` (6 fases). Decisiones: sin hibernar, sin confirmaciones, wallust + Catppuccin.

## 2026-10-20 — Sesión 2: implementación
- [x] Fase 0: copia en `~/.config/wlogout.bak-2026-10-20`, `git init`, capturas y tiempos de partida.
- [x] Fase 1:
  - Cerrar sesión → `hyprctl dispatch 'hl.dsp.exit()'`. Confirmado que `dispatch 'exit 0'` da error de sintaxis Lua.
  - Hibernar eliminado.
  - `LockScreen.sh` bloquea primero y refresca el tiempo después con `setsid -f` (antes, ~1 s de espera con red; más sin ella).
  - CSS sin avisos de GTK (antes: «Not using units is deprecated»).
- [x] Fase 2: `Wlogout.sh` pasa de 58 a 21 líneas, con una sola llamada a `hyprctl | jq`, sin `awk` y con `exec`.
      Fila de 5 tarjetas centrada en cualquier resolución.
      Apertura medida: 195 ms antes y 194 ms después (media de 5). Casi todo es arranque de GTK; no hay mejora apreciable.
- [x] Fase 3: 16 PNG (1,1 MB) → 5 SVG simbólicos (2,3 KB), sacados de Font Awesome 7 Solid (mismo estilo)
      y recoloreados con `-gtk-recolor`. Sin iconos «-hover».
- [x] Fase 4:
  - Plantilla `wallust/templates/colors-wlogout.css` → `wlogout/colors.css` (fondo, primer plano, color4, color12).
  - Neutros Catppuccin; hover de reiniciar en peach y de apagar en red.
  - Foco con borde claro, distinto del hover.
  - Textos en español con la tecla visible; orden por uso.
  - Contraste con la paleta actual: texto 7,6:1, hover 7,3–10,6:1, borde de foco 10,2:1 (AA).
- [x] Fase 5: layer rule `animation = "fade"` para `logout_dialog`. KeyHints corregido (Super + L).
      Comentario de hypridle corregido.
- [x] Fase 6 (parcial): capturas en los dos monitores, estados hover y foco con CSS de prueba, 0 avisos de GTK.
- [ ] Pendiente (usuario): probar las teclas y los clics de verdad. Con
      `WLOGOUT_LAYOUT=~/.config/wlogout/layout.test ~/.config/hypr/scripts/Wlogout.sh` no se ejecuta nada real.
- [ ] Riesgo conocido: si un fondo de pantalla da un `color12` oscuro, el texto oscuro del hover perdería contraste.
      Revisar si pasa.

## 2026-10-20 — Sesión 3: rediseño con dos variantes para elegir
- [x] Orden: Apagar, Reiniciar, Suspender, Bloquear, Cerrar sesión. Textos sin la tecla.
- [x] Colores más vivos: `color13 | saturate(0.5) | lighten(0.35)` y `color12 | saturate(0.5) | lighten(0.45)`.
      Probado con 40 fondos al azar: texto oscuro encima ≥ 4,58:1 en todos (antes `color12` fallaba en 25 de 40).
- [x] Fondo menos oscuro (opacidad 0,82 → 0,62).
- [x] Variante `cards` (por defecto): rejilla 3+2 de tarjetas grandes; icono en color en reposo y degradado en hover.
      Apagar en red→maroon, Reiniciar en peach→yellow.
      wlogout rellena por columnas y no puede centrar la fila incompleta: la sexta celda queda oculta (abajo a la derecha).
- [x] Variante `menu`: columna de filas unidas, con el icono a la izquierda.
      Las claves `width`/`height` del layout no funcionan en wlogout 1.2.2 (con cualquier valor el texto va abajo a la derecha);
      se alinea con relleno en el CSS + etiquetas de 13 caracteres.
- [x] `Wlogout.sh [cards|menu]`, o `~/.config/wlogout/variant`; `WLOGOUT_TEST=1` genera un layout de prueba en `$XDG_RUNTIME_DIR`.
- [ ] Pendiente (usuario): elegir variante; luego se borra la otra.

## 2026-10-21 — Sesión 4: vuelta al estilo original
- [x] El usuario prefiere el aspecto inicial: se restauran `style.css` e iconos PNG del commit a135330.
      Se borran las variantes cards/menu, los SVG, `colors.css` y la plantilla de wallust.
- [x] Se mantienen los arreglos invisibles: cerrar sesión con `hl.dsp.exit()`, sin hibernar, bloqueo inmediato,
      `margin: 50px 35px` y `WLOGOUT_TEST=1`.
- [x] Orden en la rejilla: Shutdown · Reboot · Suspend arriba, Lock · Logout abajo. La sexta celda queda oculta.
- [x] Iconos sin uso borrados (hibernate*, moon, sleep2, Other icons): 1,1 MB → 100 KB.

## 2026-10-21 — Sesión 5: cristal simulado y animaciones sobre el estilo original
- [x] Sin blur (decisión del usuario): tarjetas translúcidas (surface0 al 78 %), borde claro arriba,
      reflejo diagonal y sombra. Fondo con viñeta radial.
- [x] Hover/foco: el mismo lila de antes, translúcido y con brillo; el icono crece un poco (20 % → 22 %).
- [x] Animaciones GTK: entrada escalonada (aparecen subiendo 30 px, con 60 ms entre tarjetas en orden de lectura)
      y brillo pulsante en la tarjeta con foco. Comprobado con capturas cada ~30 ms.
- [x] Animaciones más rápidas: entrada en 260 ms con 30 ms entre tarjetas y transiciones de 150 ms.
      Medido: el menú queda completo a los ~240 ms de aparecer (antes, más de 500 ms).
- [x] Entrada a 144 Hz. Medido con WAYLAND_DEBUG (intervalo entre commits de wl_surface): iba a ~40 fps.
      Causas: la viñeta radial a pantalla completa (GTK3 dibuja con la CPU) y animar margin (recoloca la rejilla).
      Ahora: fondo plano, solo fundido escalonado y sombra de 14px → mediana de 7,6 ms (~132 fps).
      Probado y descartado: iconos reducidos a 128px (sin efecto), subir el icono (96 fps), animar colores (81 fps).

## 2026-10-21 — Sesión 6: flechas con vuelta
- [x] wlogout 1.2.2 parcheado (`src/wlogout-flechas.patch`, `src/build.sh`; el binario va a `bin/`, ignorado por git).
      En un borde, las flechas dan la vuelta; en vertical, si la celda está vacía, va al botón más cercano a la izquierda.
      Además se corrige la lectura fuera de rango que creaba la sexta celda fantasma (Gtk-CRITICAL).
- [x] `Wlogout.sh` usa `bin/wlogout`; si falta, el del sistema.
- [x] Probado con `hl.dsp.send_shortcut` y detección del foco por color: 19/19 en la mayoría de las ejecuciones.
      En algunas, wlogout se cerró a mitad de prueba (proceso y capa desaparecidos, causa sin confirmar).
      El usuario pidió parar las pruebas; no hay más simulaciones.
      Enter, las teclas rápidas y Escape siguen funcionando.
