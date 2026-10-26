# Progreso

## Fase 0: Preparación (2026-10-21)
- [x] Repositorio git en `~/.config/waybar` (se ignora `wallust/colors-waybar.css`, que se genera solo).
- [x] Estilo copiado a `style/Fusion Personalizada.css` y `style.css` apuntando a él.
      `style/[0 VERTICAL] Golden Noir.css` contiene la misma copia porque el original se sobrescribió.
- [x] Captura de referencia en `capturas/fase0-barra.png`.

## Fase 1: Contraste (2026-10-21)
- [x] ~~Fondo continuo semiopaco con borde de acento~~: revertido a petición del usuario, que prefiere la barra totalmente transparente.
- [x] Halo oscuro (`text-shadow` y `-gtk-icon-shadow`) tras texto e iconos para separarlos de fondos claros sin dibujar caja.
- [x] `scripts/contraste.py` se conserva, pero solo es válido si se vuelve a poner fondo a la barra.
- [ ] Blur: descartado de momento, porque está desactivado globalmente en Hyprland (`UserDecorations.lua`).
- Nota: `pkill -SIGUSR2 waybar` cerró Waybar una vez. Para recargar es más fiable:
  `pkill waybar; setsid -f waybar`.

## Fase 2: Clima (2026-10-21)
- [x] `scripts/clima.py`: Open-Meteo para Jaén, solo biblioteca estándar, caché de 14 min en `~/.cache/clima/`.
- [x] Tooltip en español: bloque «ahora» centrado; próximas horas o próximos días (con la rueda) con icono, temperatura, estado en texto y lluvia.
- [x] Clic: actualizar · clic derecho: AEMET Jaén · señal 8 para refrescar al instante.
- [x] Sin red: muestra los últimos datos con la clase `.sin-conexion` (atenuada).
- [x] `WeatherWrap.sh` y `Weather.py` enviados a la papelera. `clima.py` escribe ahora `~/.cache/.weather_cache` para hyprlock y `LockScreen.sh` lo llama al bloquear.

## Fase 3: Calendario (2026-10-21)
- [x] Tooltip nativo: `locale` es_ES, un mes, semana empieza en lunes, hoy resaltado en mauve, letra más grande y sin números de semana.
- Nota: `size=` dentro de los formatos del calendario hace que Waybar no muestre el tooltip.
- [x] `actions` movido dentro de `clock` (antes estaba fuera y Waybar lo ignoraba).
- [x] Rueda: cambia de mes (o de año en vista anual) · clic derecho: mes/año · clic central: hoy.
- [x] `format-alt` con la fecha larga en español; se conservan los segundos.

## Fase 4: Optimización (2026-10-21)
- [x] `cpu` de 1 s a 3 s y `network#speed` de 1 s a 2 s. El reloj sigue a 1 s por los segundos.
- [x] Quitadas 4 `animation: gradient_f`, que apuntaban a un `@keyframes` inexistente.
- [x] Waybar arranca sin avisos (solo los del applet de red). Uso medido: ~1,8 % de CPU en 30 s.
- [ ] Separadores `blank_3`: se mantienen. Cambiarlos por márgenes no ahorra nada y podría mover la barra.
