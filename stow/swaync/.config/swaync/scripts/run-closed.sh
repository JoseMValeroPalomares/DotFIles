#!/usr/bin/env bash
# Cierra el centro de control y lanza el comando (lock, wlogout...)
swaync-client -cp >/dev/null
exec "$@"
