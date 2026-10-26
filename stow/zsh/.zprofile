#if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
#       Hyprland 
#fi

# Created by `pipx` on 2026-04-13 14:10:51
export PATH="$PATH:/home/jose/.local/bin"

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec uwsm start hyprland-uwsm.desktop
fi
