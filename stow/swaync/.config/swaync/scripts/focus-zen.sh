#!/usr/bin/env bash
# Trae Zen al frente al pulsar una de sus notificaciones. Sin esto Hyprland solo la marca como
# urgente, porque focus_on_activate está desactivado. Lo lanza swaync ("scripts" en config.json).
# Con la config en Lua, hyprctl dispatch recibe una expresión Lua.
exec hyprctl dispatch 'hl.dsp.focus({ window = "class:^(zen)$" })'
