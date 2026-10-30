# SwayNC

![SwayNC](../../docs/capturas/swaync.png)

Centro de notificaciones arriba a la derecha (420 px), con tema propio basado en tokens de wallust.

## Qué incluye

- `config.json`: posición, tamaños, widgets (botones rápidos, volumen, brillo, MPRIS).
- `style.css`: estilo completo por secciones (tokens, panel, tarjetas, widgets).
- `scripts/`: botones del panel, generador de iconos y `notifyd`.

## Iconos

`scripts/gen-icons.py` genera todos los PNG de `icons/` e `images/` con la paleta de wallust y los
glifos de la Nerd Font, así que combinan con cada fondo. `WallustSwww.sh` lo lanza al cambiar de
fondo. Los PNG no se versionan y conservan los nombres de siempre, de modo que los scripts de
Hyprland no necesitan saber nada. Los errores van en baldosa roja rellena con cualquier fondo.

## Avisos del sistema (`notifyd`)

Servicio de usuario (`notifyd.service`) que convierte eventos en notificaciones:

| Aviso | Cuándo | Botones |
|---|---|---|
| Batería | Al bajar del 20, 10 y 5 % (crítico), al conectar o quitar el cargador y al llenarse | |
| Bluetooth | Al conectar o desconectar, con el nivel de batería si lo publica | |
| USB | Al insertar o retirar una unidad | Abrir, Expulsar |
| Red | Al perder la conexión o cambiar de red | |
| Descargas | Al terminar una en `~/Downloads` (Zen, Firefox, Chromium) | Abrir, Ver carpeta |
| Actualizaciones | Cada 6 h, solo si hay paquetes nuevos (pacman y AUR) | Actualizar |
| Reinicio | Si el kernel en uso ya no está instalado | |
| Disco | Al pasar del 90 y del 95 % | Abrir |
| Temperatura | CPU a 98 °C o más durante un minuto | |
| Servicios | Si falla un servicio de sistema o de usuario | Ver registro |

Sustituye a los avisos propios de nm-applet y blueman, que se desactivan al instalar.
Los umbrales son constantes al principio de `scripts/notifyd.py`.

```bash
~/.config/swaync/scripts/notifyd.py --demo            # un ejemplo de cada aviso
journalctl --user -u notifyd                          # registro del servicio
python3 -m unittest discover -s ~/.config/swaync/tests
```

## Discord en Zen

1. En Discord: Ajustes de usuario → Notificaciones → activar las de escritorio, y aceptar el permiso
   que pide Zen. Zen no tenía permiso de notificaciones para ningún sitio.
2. La pestaña tiene que estar cargada: Discord no avisa si Zen la ha descargado.

Los avisos muestran el avatar de quien escribe, con la insignia de Zen, y al pulsarlos se enfoca Zen
(`scripts/focus-zen.sh`). Salen agrupados como «Zen» porque el navegador no indica de qué web vienen.

## Atajos

- Clic en la campana de Waybar: abrir/cerrar el panel
- Clic derecho en la campana: modo «No molestar»

## Instalar solo esto

```bash
./install.sh --only swaync
```

[← Volver al README principal](../../README.md)
