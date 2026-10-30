# Plan de mejora de swaync

Versión instalada: **swaync 0.12.6** (GTK4) · Hyprland · 2 monitores 1920×1080 (eDP-1 y HDMI-A-1) · colores de wallust (`~/.config/waybar/wallust/colors-waybar.css`).

## 1. Diagnóstico

### Estructura y mantenimiento
- `style.css` tiene reglas **duplicadas que se pisan**: `.floating-notifications .notification` aparece 3 veces, `.widget-title` 3 veces y `.control-center .notification` 2 veces. Lo que se ve en pantalla es la última, y las anteriores solo confunden.
- `style2.css` es una copia antigua que no se usa. Además lleva `cursor: pointer`, que GTK no admite.
- `config.json` tiene permiso de ejecución sin necesidad (`rwx`).

### Posicionamiento (la parte más frágil)
- Las notificaciones flotantes están en `positionX: "center"` y se empujan con `margin-left: 1200px`. Es un apaño: el resultado depende del ancho del monitor y se rompe si cambia la resolución o la escala.
- Los anchos no coinciden: `notification-window-width: 280` en la config y `min-width: 320px` en el CSS.

### Visual
- La paleta está mezclada: hay colores de wallust (`@color12`), rosa de Tokyo Night fijado a mano (`#f7768e`) y fondos de Catppuccin (`rgba(24,24,37)`, `rgba(30,30,43)`). Por eso al cambiar de fondo de pantalla no cambia todo a la vez.
- `* { font-weight: bold }` pone todo en negrita y no queda jerarquía entre título, cuerpo y hora.
- Con `@background-alt` = `rgba(0,0,6,0.25)` sobre un panel casi negro, las tarjetas apenas se distinguen del fondo.
- `backdrop-filter: blur()` **no funciona en GTK4**: se ignora. El desenfoque solo puede venir de una *layerrule* de Hyprland.
- Al pasar el ratón, `border-left` pasa de 4px a 6px y el contenido se desplaza (salto visible).
- No hay estilo distinto por urgencia (`.low`, `.normal`, `.critical`): una alerta crítica se ve igual que un aviso de Spotify.
- Los OSD de volumen y brillo (`Volume.sh`, `BrightnessKbd.sh`) envían `int:value`, pero la barra de progreso no tiene estilo.
- Los títulos de las notificaciones flotantes usan `@color12` (#CA9681) sobre casi negro. Hay que comprobar el contraste AA (4.5:1) del cuerpo con `alpha 0.8` y de la hora con `alpha 0.6`.

### Usabilidad y accesibilidad
- Las barras de scroll están ocultas del todo (0px y transparentes). En un panel de 850px no hay ninguna pista de que hay más contenido.
- `keyboard-shortcuts: true` está activo, pero no hay estilo `:focus-visible` en botones, interruptores ni notificaciones, así que no se ve qué elemento tiene el foco.
- Los botones del grid son solo iconos y no indican si algo está activado (silencio, Bluetooth).

### Rendimiento y arranque
- `transition: all` y sombras grandes y dobles en cada notificación flotante. Conviene animar solo las propiedades necesarias y usar sombras más baratas.
- **Doble arranque:** `Startup_Apps.lua` lanza `swaync` y además lo activa D-Bus (`swaync.service`). En el journal salen 5 fallos seguidos de "already running" hasta llegar a `start-limit-hit`.

## 2. Dirección visual propuesta

**"Glass" sobrio con acento de wallust.** Las superficies son translúcidas y el desenfoque lo pone Hyprland. Un único color de acento sale de wallust y todo lo demás se deriva de él con `alpha()`/`mix()`. Las esquinas se unifican (14px en tarjetas y 18px en el panel), y el resplandor neón queda solo para las notificaciones críticas. Así el tema se adapta solo a cada fondo de pantalla.

## 3. Fases

### Fase 0 — Preparación
- [x] Hacer `git init` en `~/.config/swaync` y un commit inicial con el estado actual, para poder volver atrás.
- [x] Pasar `style2.css` a `backup/` y quitar el `+x` de `config.json`.
- [x] Crear `test-notify.sh` con notificaciones de prueba: low, normal y critical, con y sin imagen, con acciones, con texto largo, con progreso (`int:value`) y varias seguidas de la misma app.

### Fase 1 — Limpieza del CSS (sin cambiar el aspecto)
- [x] Reescribir `style.css` en secciones con un bloque por selector: tokens, base, panel, tarjeta de notificación, flotantes, widgets.
- [x] Definir tokens únicos (`@define-color accent`, `surface`, `surface-alt`, `text`, `text-muted`, `danger`, `warning`) a partir de wallust. Quitar los hex fijos.
- [x] Comprobar con `swaync-client -rs` y el journal que no salen avisos del parser CSS.

### Fase 2 — Posicionamiento y config
- [x] Usar `positionX: "right"` y `positionY: "top"`, quitar `margin-left: 1200px` y dejar un margen pequeño (unos 10px; arriba, el alto de waybar).
- [x] Hacer que coincidan `notification-window-width` y el ancho del CSS (380, solo en la config).
- [x] Revisar las opciones de 0.12: `relative-timestamps`, `notification-grouping`, `control-center-positionX: "right"` (el panel junto a las flotantes) y `control-center-exclusive-zone`.
- [x] Añadir `notification-visibility` para Spotify y los reproductores (low o transient) y para los OSD de volumen y brillo (`transient`, que no se queden en el historial).
- [x] Botones del grid con `"type": "toggle"` y estado activo (WiFi, Bluetooth, silencio y micro con `scripts/toggle.sh`).

### Fase 3 — Notificaciones flotantes
- [x] Una sola tarjeta: radio uniforme, borde de 1px y una franja de acento de 3px que no cambia de ancho al pasar el ratón (sin saltos).
- [x] Jerarquía de texto: título 600 a 14px, cuerpo 400 a 12.5px y hora 400 a 11px, todos con contraste AA comprobado.
- [x] Estilos por urgencia: `.low` más discreta, `.critical` con el acento `danger` y resplandor.
- [x] Barra de progreso con estilo para los OSD de volumen y brillo.
- [x] Botones de acción y respuesta en línea con estados hover, active y `:focus-visible`.
- [x] Imágenes: icono de 48px con radio y `body-image` con proporción controlada.

### Fase 4 — Centro de control
- [x] Cabecera: título y botón "Borrar" alineados, con un separador fino en degradado (uno solo).
- [x] Grid de botones: 48px, estado activo visible (swaync 0.12 no permite tooltips).
- [x] MPRIS: carátula, título y artista con elipsis, y controles con estados.
- [x] Volumen y brillo con barras más gruesas y el acento en el `highlight`.
- [x] Estado vacío ("Sin notificaciones") con icono y texto atenuado.
- [x] Scrollbar fina (unos 4px) que solo se ve al hacer hover o scroll.
- [x] Separación vertical uniforme entre widgets (escala 4/8/12/16).

### Fase 5 — Integración con Hyprland *(archivos fuera de este proyecto, se tocan solo si das permiso)*
- [x] `layerrule` con blur e `ignore_alpha` para `swaync-control-center` y `swaync-notification-window`. **Ojo:** solo se nota con `decoration.blur.enabled`, que está desactivado en `UserDecorations.lua`; mientras tanto el panel usa una opacidad de 0.80.
- [x] Animación de entrada y salida de las capas (slide o fade) en Hyprland, en lugar de animarlas en CSS.
- [x] Quitar `hl.exec_cmd("swaync")` de `Startup_Apps.lua` y dejar que arranque por D-Bus o por `systemctl --user enable swaync`, para que no haya doble arranque.

### Fase 6 — Verificación final
- [x] Ejecutar `test-notify.sh` en los dos monitores y sacar capturas con `grim` (flotantes, panel lleno, panel vacío, crítica, OSD).
- [ ] Probar con 2–3 fondos de wallust distintos para confirmar que el tema se adapta (pendiente: no cambio tu fondo sin pedírtelo; todos los colores salen de wallust).
- [x] Comprobar el contraste de los pares texto/fondo con los colores reales de wallust.
- [x] Navegar con teclado por el panel (foco visible) y revisar que el journal está limpio.

### Fase 7 — Más avisos e iconos coherentes (2026-10-30)
- [x] Iconos generados con la paleta de wallust (`scripts/gen-icons.py`), mismos nombres de archivo.
- [x] `notifyd`: batería, Bluetooth, USB, red, descargas, actualizaciones, reinicio, disco, temperatura y servicios.
- [x] Avisos de Zen: avatar sin deformar, duración normal y foco al pulsar.
- [ ] Probar con hardware real: USB y Bluetooth.

## 4. Decisiones (resueltas el 2026-10-20)
1. Las notificaciones van arriba a la derecha.
2. Estética "glass sobrio".
3. Hay permiso para tocar `~/.config/hypr`.
