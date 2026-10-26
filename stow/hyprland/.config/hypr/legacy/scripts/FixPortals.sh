#!/bin/bash
# Esperar un momento a que Hyprland exporte las variables
sleep 1 

# Matar todos los portales conflictivos
killall -9 xdg-desktop-portal-hyprland
killall -9 xdg-desktop-portal-wlr
killall -9 xdg-desktop-portal-gnome
killall -9 xdg-desktop-portal

sleep 1

# Iniciar el portal de Hyprland primero y luego el genérico
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &