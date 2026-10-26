#!/usr/bin/env python3
# Genera las filas del menú de atajos (SUPER+SHIFT+K) a partir de `hyprctl binds -j`:
# siempre refleja los atajos cargados de verdad. Salida: filas con marcado pango para rofi.

import json
import re
import subprocess
from html import escape
from pathlib import Path

COLORS_FILE = Path.home() / ".config/rofi/wallust/colors-rofi.rasi"

MODS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]

KEY_NAMES = {
    "return": "Enter", "space": "Espacio", "tab": "Tab", "delete": "Supr", "print": "ImprPant",
    "up": "↑", "down": "↓", "left": "←", "right": "→",
    "bracketleft": "[", "bracketright": "]", "comma": ",", "period": ".",
    "mouse:272": "Clic izq.", "mouse:273": "Clic der.", "mouse_up": "Rueda ↑", "mouse_down": "Rueda ↓",
    "xf86audioraisevolume": "Vol +", "xf86audiolowervolume": "Vol −", "xf86audiomute": "Silencio",
    "xf86audiomicmute": "Micro", "xf86audioplay": "Play", "xf86audiopause": "Pausa",
    "xf86audionext": "Siguiente", "xf86audioprev": "Anterior", "xf86audiostop": "Stop",
    "xf86monbrightnessup": "Brillo +", "xf86monbrightnessdown": "Brillo −",
    "xf86kbdbrightnessup": "Luz teclado +", "xf86kbdbrightnessdown": "Luz teclado −",
    "xf86touchpadtoggle": "Touchpad", "xf86rfkill": "Modo avión", "xf86sleep": "Suspender",
}
# Las teclas de número de los escritorios llegan solo como keycode
KEYCODES = {10 + i: str((i + 1) % 10) for i in range(10)}

# (categoría, icono Nerd Font, palabras clave) en el orden en que se muestran
CATEGORIES = [
    ("Grupos", "\U000f0e05", ["group"]),
    ("Escritorios", "\U000f0570", ["workspace", "monitor"]),
    ("Ventanas", "\U000f05af", ["window", "focus", "float", "fullscreen", "maximize", "resize", "master",
                                "pseudo", "split", "dwindle", "opacity", "bring active", "terminate"]),
    ("Aplicaciones", "\U000f003b", ["terminal", "launcher", "file manager", "browser", "calculator",
                                    "clipboard", "emoji", "music", "productivity", "notification"]),
    ("Capturas", "\U000f0100", ["screenshot"]),
    ("Audio y brillo", "\U000f075a", ["volume", "track", "play", "pause", "stop", "mute", "mic", "brightness"]),
    ("Apariencia", "\U000f03d8", ["wallpaper", "theme", "waybar", "blur", "animations", "night light",
                                  "refresh", "overview", "zoom"]),
    ("Sistema", "\U000f0493", ["keyboard"]),
]
# Orden de comprobación: lo más específico primero (p. ej. "waybar layout" es Apariencia, no Ventanas)
MATCH_ORDER = ["Sistema", "Grupos", "Escritorios", "Capturas", "Audio y brillo", "Apariencia",
               "Ventanas", "Aplicaciones"]

# hyprctl solo da la última tecla de los atajos hechos solo de modificadores ("ALT_L + SHIFT_L")
MOD_ONLY = {"shift_l": ["Alt izq.", "Shift izq."], "alt_l": ["Shift izq.", "Alt izq."]}

# Atajos numerados que se muestran en una sola fila
COLLAPSE = [
    (re.compile(r"^workspace (\d+)$"), "go to workspace 1–10"),
    (re.compile(r"^move to workspace (\d+)$"), "move window to workspace 1–10"),
    (re.compile(r"^move silently to workspace (\d+)$"), "move window silently to workspace 1–10"),
    (re.compile(r"^go to window (\d+) in group$"), "go to window 1–8 in group"),
]


def colors():
    found = {}
    try:
        for line in COLORS_FILE.read_text().splitlines():
            m = re.match(r"\s*([\w-]+):\s*(#[0-9A-Fa-f]{6})\s*;", line)
            if m:
                found[m.group(1)] = m.group(2)
    except OSError:
        pass
    return {"fg": found.get("foreground", "#cdd6f4")}


def key_name(bind):
    key = bind["key"] or KEYCODES.get(bind["keycode"], f"code:{bind['keycode']}")
    return KEY_NAMES.get(key.lower(), key.upper() if len(key) == 1 else key)


def category(desc):
    low = desc.lower()
    by_name = {name: (name, icon, words) for name, icon, words in CATEGORIES}
    for name in MATCH_ORDER:
        _, icon, words = by_name[name]
        if any(w in low for w in words):
            return name, icon
    return by_name["Sistema"][:2]


def main():
    binds = json.loads(subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True).stdout)
    c = colors()
    rows, seen = [], set()
    for b in binds:
        desc = b["description"] if b["has_description"] else "(sin descripción)"
        if b["modmask"] == 0 and b["key"].lower() in MOD_ONLY:
            keys = list(MOD_ONLY[b["key"].lower()])
        else:
            keys = [name for bit, name in MODS if b["modmask"] & bit] + [key_name(b)]
        for pattern, label in COLLAPSE:
            if pattern.match(desc):
                desc = label
                keys[-1] = "1…8" if "group" in label else "1…0"
                break
        ident = (desc, tuple(keys))
        if ident in seen:
            continue
        seen.add(ident)
        rows.append((category(desc), keys, desc[0].upper() + desc[1:]))

    order = {name: i for i, (name, _, _) in enumerate(CATEGORIES)}
    rows.sort(key=lambda r: (order[r[0][0]], r[2].lower()))

    cap_text = lambda keys: "  ".join(f" {k} " for k in keys)
    width = max(len(cap_text(k)) for _, k, _ in rows) + 3
    cat_width = max(len(name) for name, _, _ in CATEGORIES) + 2

    # Sin colores de texto fijos: así se lee igual en la fila normal y en la seleccionada (fondo de acento)
    for (cat, icon), keys, desc in rows:
        caps = "  ".join(
            f'<span background="{c["fg"]}" bgalpha="14%" weight="bold"> {escape(k)} </span>' for k in keys
        )
        pad = " " * (width - len(cap_text(keys)))
        cat_col = f'{icon} <span alpha="60%">{cat.ljust(cat_width)}</span>'
        print(f"{cat_col}{caps}{pad}{escape(desc)}")

if __name__ == "__main__":
    main()
