# wlogout

![wlogout](../../docs/capturas/wlogout.png)

Menú de energía con iconos propios. Usa un wlogout 1.2.2 parcheado para navegar con flechas, que el instalador compila (`src/build.sh`).

## Qué incluye

- `layout` y `style.css`: botones y estilo.
- `icons/`: iconos normales y hover.
- `src/wlogout-flechas.patch` y `src/build.sh`: el parche y su compilación.

## Atajos

- Super+L: abrir/cerrar

## Instalar solo esto

```bash
./install.sh --only wlogout
```

Funciona mejor junto a: hyprland, lock. Sin ellos no falla nada, solo deja de responder lo que dependa de ellos.

[← Volver al README principal](../../README.md)
