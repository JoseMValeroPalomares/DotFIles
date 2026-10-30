#!/usr/bin/python3
"""Genera los iconos de las notificaciones con la paleta de wallust.

Cada icono es una baldosa redondeada con un glifo de Material Design (Nerd Font),
los mismos que usan Waybar y el panel de swaync. Los PNG se generan aquí y no se
versionan: cambian con cada fondo. Los nombres de images/ e icons/ se mantienen
para que los scripts de Hyprland no tengan que saber nada de esto.

Uso: gen-icons.py [--force] [--out DIR]
"""
import argparse
import colorsys
import hashlib
import os
import re
import subprocess
from pathlib import Path

BASE = Path.home() / ".config/swaync"
COLORS = Path.home() / ".config/waybar/wallust/colors-waybar.css"
FONT = "JetBrainsMono Nerd Font"
SIZE = 128

# Si wallust aún no ha corrido (primera instalación)
DEFAULT_PALETTE = {"background": "#171718", "foreground": "#E6CED3", "color12": "#52576C"}

# Neutros fijos, los mismos que @ink y @glass en style.css
INK, GLASS = "#f2f4f7", "#12141a"

# Colores con significado: no dependen del fondo para que un error siempre parezca un error
FIXED_ROLES = {"ok": "#86dca3", "warn": "#f7c873", "danger": "#ff7f85"}

# nombre: (glifo, papel)
ICONS = {
    # images/ (nombres heredados que usan los scripts de Hyprland)
    "images/ja": (0xF05E1, "accent"),         # confirmación genérica
    "images/error": (0xF015A, "danger"),
    "images/note": (0xF02FD, "accent"),
    "images/bell": (0xF009E, "accent"),
    # icons/ heredados
    "icons/volume-high": (0xF057E, "accent"),
    "icons/volume-mid": (0xF0580, "accent"),
    "icons/volume-low": (0xF057F, "accent"),
    "icons/volume-mute": (0xF075F, "muted"),
    "icons/microphone": (0xF036C, "accent"),
    "icons/microphone-mute": (0xF036D, "muted"),
    "icons/brightness-20": (0xF00DC, "accent"),
    "icons/brightness-40": (0xF00DD, "accent"),
    "icons/brightness-60": (0xF00DE, "accent"),
    "icons/brightness-80": (0xF00DF, "accent"),
    "icons/brightness-100": (0xF00E0, "accent"),
    "icons/music": (0xF075A, "accent"),
    "icons/palette": (0xF03D8, "accent"),
    "icons/picture": (0xF02E9, "accent"),
    "icons/timer": (0xF051B, "accent"),
    "icons/dropper": (0xF020A, "accent"),
    "icons/vpn": (0xF0BC4, "accent"),
    "icons/backup": (0xF006F, "accent"),
    "icons/uptime": (0xF0150, "accent"),
    "icons/battery-status": (0xF0083, "danger"),
    # Scripts de Hyprland que antes usaban ja.png o ninguno
    "icons/game": (0xF0297, "accent"),
    "icons/turbo": (0xF04C5, "accent"),
    "icons/touchpad": (0xF037D, "accent"),
    "icons/airplane": (0xF001D, "accent"),
    "icons/keyboard": (0xF030C, "accent"),
    "icons/night": (0xF0594, "accent"),
    "icons/emoji": (0xF01F5, "accent"),
    "icons/layout": (0xF0758, "accent"),
    "icons/monitor": (0xF037A, "accent"),
    "icons/camera": (0xF0100, "accent"),
    "icons/shield": (0xF099D, "warn"),
    # notifyd
    "icons/battery-low": (0xF007B, "warn"),
    "icons/battery-critical": (0xF0083, "danger"),
    "icons/battery-charging": (0xF0084, "ok"),
    "icons/battery-full": (0xF17E2, "ok"),
    "icons/plug": (0xF06A5, "accent"),
    "icons/plug-off": (0xF06A6, "muted"),
    "icons/bluetooth": (0xF00B1, "accent"),
    "icons/bluetooth-off": (0xF00B2, "muted"),
    "icons/headphones": (0xF02CB, "accent"),
    "icons/mouse": (0xF037D, "accent"),
    "icons/usb": (0xF129E, "accent"),
    "icons/wifi": (0xF05A9, "ok"),
    "icons/wifi-off": (0xF05AA, "warn"),
    "icons/ethernet": (0xF0200, "ok"),
    "icons/download": (0xF1464, "ok"),
    "icons/update": (0xF03D5, "accent"),
    "icons/restart": (0xF0709, "warn"),
    "icons/disk": (0xF02CA, "warn"),
    "icons/temperature": (0xF0E01, "danger"),
    "icons/service": (0xF13CE, "danger"),
}


def read_palette():
    palette = dict(DEFAULT_PALETTE)
    try:
        text = COLORS.read_text()
    except OSError:
        return palette
    palette.update(re.findall(r"@define-color\s+(\S+)\s+(#[0-9a-fA-F]{6})\s*;", text))
    return palette


def to_rgb(color):
    return tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))


def to_hex(rgb):
    return "#" + "".join(f"{round(c):02x}" for c in rgb)


def mix(a, b, amount):
    return to_hex(x + (y - x) * amount for x, y in zip(to_rgb(a), to_rgb(b)))


def luminance(color):
    def channel(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = map(channel, to_rgb(color))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def soft_accent(palette, bg):
    """El tono de color12, igual que el acento de style.css: saturación limitada para que un
    fondo cálido no acabe en naranja, y aclarado hasta que destaque sobre el fondo."""
    h, l, s = colorsys.rgb_to_hls(*(c / 255 for c in to_rgb(palette["color12"])))
    s = min(s, 0.15)
    accent = palette["color12"]
    while l < 0.9:
        accent = to_hex(c * 255 for c in colorsys.hls_to_rgb(h, l, s))
        if contrast(accent, bg) >= 6.5:
            break
        l += 0.02
    return accent


def roles(palette):
    return {**FIXED_ROLES, "accent": soft_accent(palette, GLASS), "muted": mix(INK, GLASS, 0.30)}, GLASS


def svg(glyph, role, role_color, bg):
    # Baldosa tonal: fondo oscuro teñido del color del papel y glifo en ese color.
    # Los errores van rellenos: con un fondo rojizo el tono solo no los distinguiría del acento.
    if role == "danger":
        top, bottom, ink, stroke = role_color, mix(role_color, bg, 0.20), bg, "#ffffff"
    else:
        top, bottom, ink, stroke = mix(bg, role_color, 0.34), mix(bg, role_color, 0.16), role_color, role_color
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 128 128">
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>
<rect x="3" y="3" width="122" height="122" rx="34" fill="url(#g)"/>
<rect x="4" y="4" width="120" height="120" rx="33" fill="none" stroke="{stroke}" stroke-opacity=".28" stroke-width="2"/>
<text x="64" y="93" font-family="{FONT}" font-size="74" text-anchor="middle" fill="{ink}">{chr(glyph)}</text>
</svg>"""


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="regenera aunque la paleta no haya cambiado")
    parser.add_argument("--out", type=Path, default=BASE)
    args = parser.parse_args()

    palette = read_palette()
    colors, bg = roles(palette)
    stamp = hashlib.sha256(repr(sorted(ICONS.items()) + sorted(colors.items()) + [bg]).encode()).hexdigest()
    stamp_file = args.out / "icons/.palette"
    if not args.force and stamp_file.is_file() and stamp_file.read_text() == stamp:
        return

    jobs = []
    for name, (glyph, role) in ICONS.items():
        target = args.out / f"{name}.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        tmp = target.with_suffix(".tmp.png")
        proc = subprocess.Popen(["rsvg-convert", "-o", str(tmp)], stdin=subprocess.PIPE)
        proc.stdin.write(svg(glyph, role, colors[role], bg).encode())
        proc.stdin.close()
        jobs.append((proc, tmp, target))
    for proc, tmp, target in jobs:
        if proc.wait() == 0:
            os.replace(tmp, target)    # atómico: una notificación nunca ve un PNG a medias
    stamp_file.write_text(stamp)


if __name__ == "__main__":
    main()
