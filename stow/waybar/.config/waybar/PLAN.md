# Plan de mejora de Waybar

Barra inferior (`configs/2`) con estilo `style/Fusion Personalizada.css`.
Colores de iconos: Catppuccin Mocha fijos. Wallust aporta fondo y acentos.

## Decisiones
- Ubicación del clima: Jaén (coordenadas fijas, sin geolocalización por IP).
- Icono del clima en la barra: se mantiene. Se rehace el tooltip y la interacción.
- Tres grupos de módulos (izquierda, centro, derecha) que visualmente forman una barra continua.
- El reloj conserva los segundos.
- Calendario: tooltip nativo de Waybar (es_ES, un mes, navegación con rueda y clics).

## Fases
0. **Preparación**: git, estilo propio fuera de los estilos originales, captura de referencia.
1. **Contraste**: fondo continuo semiopaco (`color0` de Wallust) + blur de Hyprland
   (`layer_rule` del namespace `waybar` con `ignore_alpha`), borde de acento de Wallust,
   y un script que compruebe el contraste WCAG (≥ 4,5:1 en texto e iconos).
2. **Clima**: script nuevo en Python con solo la biblioteca estándar (Open-Meteo),
   tooltip en español ordenado (ahora, próximas horas, próximos días), caché de 15 min,
   sin ping ni ipinfo, clase `.stale` cuando no hay red, y acciones de clic que funcionen.
3. **Calendario**: `mode: month`, `locale: es_ES.UTF-8`, `actions` dentro de `clock`
   (rueda = mes, clic derecho = mes/año, clic central = hoy). `format-alt` con la fecha larga.
4. **Optimización y pulido**: `network#speed` a 2–3 s, separadores con `margin` en CSS,
   quitar las animaciones `gradient_f` que no existen, revisión final.

## Verificación de cada fase
- `pkill -SIGUSR2 waybar` para recargar.
- Captura con `grim` de la franja de la barra sobre un fondo claro y otro oscuro.
