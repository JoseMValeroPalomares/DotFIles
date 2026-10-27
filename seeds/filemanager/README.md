# Thunar (gestor de archivos)

![Thunar (gestor de archivos)](../../docs/capturas/filemanager.png)

Thunar con acciones personalizadas, atajos propios, miniaturas (tumbler, ffmpegthumbnailer) y unidades (gvfs).

## Qué incluye

- `Thunar/accels.scm` y `uca.xml` (acciones del menú contextual).
- `xfce4/xfconf/xfce-perchannel-xml/thunar.xml` (preferencias) y `xfce4/helpers.rc`.
- Todo va en semillas porque Thunar reescribe estos archivos al cerrarse.

## Atajos

- Super+E: abrir Thunar

## Instalar solo esto

```bash
./install.sh --only filemanager
```

[← Volver al README principal](../../README.md)
