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

## Fase 5: Legibilidad y suspensión (2026-10-30)
- [x] Medido con una Waybar temporal sobre fondos difíciles: contraste real de cada color frente a los píxeles que lo rodean. Antes, 1,0 a 1,3 sobre blanco y amarillo.
- [x] Halo de 7 capas apiladas (`text-shadow` y `-gtk-icon-shadow`). Una capa opaca sola se queda corta sobre blanco. Sobre fondo oscuro casi no se aprecia.
- [x] Paleta aclarada sin cambiar el tono. Resultado: mínimo 3,1 sobre blanco, 3,8 sobre amarillo y fondos muy variados, 6 sobre gris y azul, 12 sobre negro. Blanco puro sigue por debajo de 4,5: subirlo más exigiría fondo, descartado en la fase 1.
- [x] `#temperature.critical` sin halo: es texto oscuro sobre caja roja.
- [x] `custom/modo-pensando` junto al brillo: luna = suspensión normal, café = no se suspende. Clic: `ThinkingMode.sh` (el mismo del atajo) y señal 10. El atajo se refleja en 2 s como mucho, por el intervalo: `ThinkingMode.sh` está en hypr y no manda señal.
- [x] `scripts/modo_pensando.sh` ancla el `pgrep`. Ojo: el `pgrep` sin anclar de `ThinkingMode.sh` coincide con cualquier proceso que cite el texto completo del inhibidor, y lo mata al desactivar.
- [x] `clima.py`: temporal por proceso. Con dos monitores se lanzaba dos veces, uno fallaba al renombrar y ese monitor se quedaba sin tiempo hasta 15 min.
- Uso de CPU: ~1,0 % → ~1,7 % (30 s). Captura en `capturas/fase5-antes-despues.png`.
