# Waybar

![Waybar](../../docs/capturas/waybar.png)

Barra inferior con escritorios, multimedia, clima (Open-Meteo, sin API key), sistema y bandeja.

## Qué incluye

- `configs/` (42 diseños) y `style/` (58 estilos); los activos son `configs/2` y `style/Fusion Personalizada.css`.
- `Modules`, `ModulesCustom`, `ModulesGroups`, `ModulesWorkspaces`: definición de los módulos.
- `scripts/clima.py`: tiempo y previsión para el tooltip y hyprlock.
- Semillas: el enlace `config`/`style.css` activo y los colores de wallust.

## Atajos

- Clima: clic para actualizar; rueda arriba/abajo para la previsión por horas o por días
- Menú de diseños y estilos desde los ajustes rápidos

## Instalar solo esto

```bash
./install.sh --only waybar
```

Funciona mejor junto a: hyprland, swaync. Sin ellos no falla nada, solo deja de responder lo que dependa de ellos.

[← Volver al README principal](../../README.md)
