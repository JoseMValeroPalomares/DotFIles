# wlogout parcheado

`Wlogout.sh` usa `~/.config/wlogout/bin/wlogout` si existe; si no, el wlogout del sistema.

`wlogout-flechas.patch` (sobre wlogout 1.2.2) cambia dos cosas en `main.c`:

1. **Flechas con vuelta.** En un borde, la flecha salta al lado contrario de la rejilla
   (en Shutdown, ← va a Suspend; en Suspend, → va a Shutdown).
   En vertical, si la celda de destino está vacía, va al botón más cercano a la izquierda (en Suspend, ↑ va a Logout).
2. **Sin celda fantasma.** El original creaba las 6 celdas de la rejilla 3×2 con solo 5 botones,
   leía `buttons[5]` fuera de rango y daba `Gtk-CRITICAL`.

Recompilar (por ejemplo, tras actualizar GTK): `~/.config/wlogout/src/build.sh`

Si el paquete wlogout se actualiza a otra versión, el parche puede necesitar ajustes.
