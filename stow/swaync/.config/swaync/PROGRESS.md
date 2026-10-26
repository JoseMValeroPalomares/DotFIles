# Progreso

- 2026-10-20: Diagnóstico hecho y plan redactado en `PLAN.md`.
- 2026-10-20: Fase 0. `git init`, `style2.css` pasa a `backup/` y se crea `test-notify.sh`.
- 2026-10-20: Fases 1–4.
  - `style.css` reescrito con tokens de wallust y cargado sin avisos del parser.
  - Popups arriba a la derecha (380px) y panel a la derecha (420px, alto de pantalla).
  - Estilos por urgencia, barra de progreso para los OSD, foco visible y scrollbar fina.
  - Toggles con estado mediante `scripts/toggle.sh`: swaync parte mal los comandos con comillas anidadas.
  - Contraste AA comprobado en el peor caso (fondo de pantalla blanco detrás): el texto más tenue da 5.07:1.
- 2026-10-20: Fase 5.
  - Reglas de capa de swaync (blur, ignore_alpha y slide) en `hypr/UserConfigs/WindowRules.lua`.
  - Quitado `exec swaync` de `Startup_Apps.lua`: ahora se activa por D-Bus y systemd lo reinicia si falla.
  - El blur global sigue desactivado (decisión previa), así que las reglas de blur se quedan latentes.
- Pendiente: probar con otros fondos de wallust y MPRIS con un reproductor abierto.
- Notas:
  - `relative-timestamps` sale en inglés ("Now"). Con `false` se ve la fecha en ISO completa, que queda peor.
  - Los glifos Nerd se ven a unos 2/3 de su `font-size`: por eso los iconos de la botonera van a 22px.
- 2026-10-20: Opacidad del panel y los popups bajada de 0.88 a 0.80 a petición.
- 2026-10-20: Con la opacidad a 0.80 se ajusta `text-faint` (0.55 → 0.62) y `danger` (#ffa3a7, tinte crítico al 10 %) para mantener AA en el peor caso.

- 2026-10-21: notificaciones flotantes 30 px más abajo (margin-top en el contenedor) y pegadas al borde derecho (padding-right 0; la ventana ya llega al borde, solo había 10 px de margen).
- 2026-10-21: popups más estrechos (340 px), 14 px de margen con el borde derecho y estilo más vivo: franja de acento a la izquierda (@accent-hi, mezcla del acento con el texto), fondo algo más claro con brillo superior, sombra más marcada, icono de 46 px y título en negrita 14 px.
- 2026-10-21: popups 20 px más a la izquierda (margen derecho 34 px); la ventana sube a 360 px para que la tarjeta conserve su ancho.
- 2026-10-21: popups 10 px más estrechos (ventana 350 px, tarjeta ~305 px), mismo margen derecho.
- 2026-10-21: popups 15 px más a la izquierda (margen derecho 49 px, ventana 365 px, tarjeta ~305 px).
