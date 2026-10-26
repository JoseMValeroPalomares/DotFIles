#!/usr/bin/env python3
"""Módulo del tiempo para Waybar (Open-Meteo, solo biblioteca estándar).

Uso:
  clima.py                 JSON para Waybar (usa la caché si tiene menos de 15 min)
  clima.py --forzar        descarga ya, ignorando la caché

Además escribe ~/.cache/.weather_cache, el texto del tiempo de hyprlock.
  clima.py --vista horas   el tooltip muestra las próximas horas
  clima.py --vista dias    el tooltip muestra los próximos días
"""
import json
import re
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path

LUGAR = "Jaén"
LAT, LON = 37.7796, -3.7849
TTL = 14 * 60  # algo menos que el intervalo de Waybar (900 s) para que siempre refresque
HORAS = 8
DIAS = 7

CACHE = Path.home() / ".cache/clima"
DATOS = CACHE / "datos.json"
VISTA = CACHE / "vista"
HYPRLOCK = Path.home() / ".cache/.weather_cache"  # lo lee hyprlock.conf

URL = (
    "https://api.open-meteo.com/v1/forecast"
    f"?latitude={LAT}&longitude={LON}&timezone=Europe%2FMadrid&forecast_days={DIAS}"
    "&current=temperature_2m,apparent_temperature,relative_humidity_2m,"
    "weather_code,is_day,wind_speed_10m,wind_direction_10m"
    "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
    "&daily=weather_code,temperature_2m_max,temperature_2m_min,"
    "precipitation_probability_max,sunrise,sunset"
)

# Catppuccin Mocha, igual que style.css
C_TITULO = "#cba6f7"   # mauve
C_TEXTO = "#cdd6f4"    # text
C_TENUE = "#7f849c"    # overlay1
C_MAX = "#fab387"      # peach
C_MIN = "#74c7ec"      # sapphire
C_LLUVIA = "#89dceb"   # sky

# Iconos Nerd Font (familia md-weather)
I_LUGAR = "\U000F034E"
I_VIENTO = "\U000F059D"
I_HUMEDAD = "\U000F058C"
I_LLUVIA = "\U000F054A"   # paraguas
I_AMANECER = "\U000F059C"
I_ATARDECER = "\U000F059B"
I_SIN_DATOS = "\U000F0F2F"

# Código WMO -> (descripción, categoría CSS, icono de día, icono de noche)
SOL, LUNA = "\U000F0599", "\U000F0594"
NUBES_SOL, NUBES_LUNA = "\U000F0595", "\U000F0F31"
NUBES = "\U000F0590"
NIEBLA = "\U000F0591"
LLOVIZNA = "\U000F0597"
LLUVIA = "\U000F0596"
NIEVE = "\U000F0598"
AGUANIEVE = "\U000F067F"
TORMENTA = "\U000F067E"
GRANIZO = "\U000F0592"

WMO = {
    0: ("Despejado", "despejado", SOL, LUNA),
    1: ("Poco nuboso", "despejado", NUBES_SOL, NUBES_LUNA),
    2: ("Parcialmente nuboso", "nubes", NUBES_SOL, NUBES_LUNA),
    3: ("Cubierto", "nubes", NUBES, NUBES),
    45: ("Niebla", "niebla", NIEBLA, NIEBLA),
    48: ("Niebla helada", "niebla", NIEBLA, NIEBLA),
    51: ("Llovizna débil", "lluvia", LLOVIZNA, LLOVIZNA),
    53: ("Llovizna", "lluvia", LLOVIZNA, LLOVIZNA),
    55: ("Llovizna intensa", "lluvia", LLOVIZNA, LLOVIZNA),
    56: ("Llovizna helada", "lluvia", AGUANIEVE, AGUANIEVE),
    57: ("Llovizna helada intensa", "lluvia", AGUANIEVE, AGUANIEVE),
    61: ("Lluvia débil", "lluvia", LLOVIZNA, LLOVIZNA),
    63: ("Lluvia", "lluvia", LLUVIA, LLUVIA),
    65: ("Lluvia intensa", "lluvia", LLUVIA, LLUVIA),
    66: ("Lluvia helada", "lluvia", AGUANIEVE, AGUANIEVE),
    67: ("Lluvia helada intensa", "lluvia", AGUANIEVE, AGUANIEVE),
    71: ("Nieve débil", "nieve", NIEVE, NIEVE),
    73: ("Nieve", "nieve", NIEVE, NIEVE),
    75: ("Nieve intensa", "nieve", NIEVE, NIEVE),
    77: ("Granos de nieve", "nieve", NIEVE, NIEVE),
    80: ("Chubascos débiles", "lluvia", LLOVIZNA, LLOVIZNA),
    81: ("Chubascos", "lluvia", LLUVIA, LLUVIA),
    82: ("Chubascos fuertes", "lluvia", LLUVIA, LLUVIA),
    85: ("Chubascos de nieve", "nieve", NIEVE, NIEVE),
    86: ("Chubascos de nieve fuertes", "nieve", NIEVE, NIEVE),
    95: ("Tormenta", "tormenta", TORMENTA, TORMENTA),
    96: ("Tormenta con granizo", "tormenta", GRANIZO, GRANIZO),
    99: ("Tormenta con granizo fuerte", "tormenta", GRANIZO, GRANIZO),
}
DIAS_SEMANA = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
RUMBOS = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]


def tiempo(codigo, es_dia=1):
    desc, cat, dia, noche = WMO.get(codigo, ("Desconocido", "nubes", NUBES, NUBES))
    return desc, cat, dia if es_dia else noche


def color(texto, c):
    return f"<span foreground='{c}'>{texto}</span>"


def leer_cache():
    try:
        return json.loads(DATOS.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def descargar():
    with urllib.request.urlopen(URL, timeout=8) as r:
        datos = json.load(r)
    datos["obtenido"] = time.time()
    CACHE.mkdir(parents=True, exist_ok=True)
    tmp = DATOS.with_suffix(".tmp")
    tmp.write_text(json.dumps(datos), encoding="utf-8")
    tmp.replace(DATOS)  # escritura atómica: Waybar nunca lee un archivo a medias
    return datos


def obtener(forzar):
    """Devuelve (datos, sin_conexion)."""
    cache = leer_cache()
    if cache and not forzar and time.time() - cache.get("obtenido", 0) < TTL:
        return cache, False
    try:
        return descargar(), False
    except (OSError, ValueError):
        return cache, True


def visible(linea):
    """Texto que se ve, sin etiquetas Pango (cada carácter ocupa una celda)."""
    return re.sub(r"<[^>]+>", "", linea)


def centrar(lineas, ancho):
    # La primera línea va en tamaño 'large' (≈1,2 veces más ancha)
    escalas = [1.2] + [1.0] * (len(lineas) - 1)
    return [" " * max(0, round((ancho - len(visible(l)) * e) / 2 / e)) + l
            for l, e in zip(lineas, escalas)]


def bloque_actual(d):
    a, hoy = d["current"], d["daily"]
    desc, _, icono = tiempo(a["weather_code"], a["is_day"])
    rumbo = RUMBOS[round(a["wind_direction_10m"] / 45) % 8]
    return [
        f"<span size='large'>{icono}  <b>{round(a['temperature_2m'])}°</b>  {desc}</span>",
        f"Sensación {round(a['apparent_temperature'])}°   "
        + color(f"Máx {round(hoy['temperature_2m_max'][0])}°", C_MAX) + "   "
        + color(f"Mín {round(hoy['temperature_2m_min'][0])}°", C_MIN),
        f"{I_VIENTO} {round(a['wind_speed_10m'])} km/h {rumbo}   "
        f"{I_HUMEDAD} {a['relative_humidity_2m']} %",
        f"{I_AMANECER} {hoy['sunrise'][0][11:]}   {I_ATARDECER} {hoy['sunset'][0][11:]}",
    ]


def lluvia(prob):
    return color(f"{I_LLUVIA} {prob:>3} %", C_LLUVIA if prob >= 30 else C_TENUE)


def bloque_horas(d):
    h = d["hourly"]
    ahora = d["current"]["time"][:13]  # "AAAA-MM-DDTHH"
    inicio = next((i for i, t in enumerate(h["time"]) if t[:13] > ahora), 0)
    indices = range(inicio, min(inicio + HORAS, len(h["time"])))
    estados = [tiempo(h["weather_code"][i], h["is_day"][i]) for i in indices]
    ancho = max(len(desc) for desc, _, _ in estados)
    filas = [color("<b>PRÓXIMAS HORAS</b>", C_TITULO)]
    for i, (desc, _, icono) in zip(indices, estados):
        filas.append(
            f"{h['time'][i][11:16]}  {icono}  {round(h['temperature_2m'][i]):>3}°  "
            f"{desc:<{ancho}}  " + lluvia(h["precipitation_probability"][i] or 0)
        )
    return filas


def bloque_dias(d):
    dd = d["daily"]
    estados = [tiempo(c) for c in dd["weather_code"]]
    ancho = max(len(desc) for desc, _, _ in estados)
    filas = [color("<b>PRÓXIMOS DÍAS</b>", C_TITULO)]
    for i, (fecha, (desc, _, icono)) in enumerate(zip(dd["time"], estados)):
        nombre = "Hoy" if i == 0 else DIAS_SEMANA[datetime.fromisoformat(fecha).weekday()]
        filas.append(
            f"{nombre:<4} {icono}  "
            + color(f"{round(dd['temperature_2m_max'][i]):>3}°", C_MAX) + " "
            + color(f"{round(dd['temperature_2m_min'][i]):>3}°", C_MIN) + "  "
            f"{desc:<{ancho}}  " + lluvia(dd["precipitation_probability_max"][i] or 0)
        )
    return filas


def salida(d, sin_conexion):
    if not d:
        return {"text": I_SIN_DATOS, "tooltip": "Sin datos del tiempo\nClic para reintentar",
                "class": "sin-datos"}

    a = d["current"]
    desc, cat, icono = tiempo(a["weather_code"], a["is_day"])
    vista = VISTA.read_text().strip() if VISTA.exists() else "horas"
    hora = datetime.fromtimestamp(d["obtenido"]).strftime("%H:%M")
    estado = f"sin conexión · datos de las {hora}" if sin_conexion else f"actualizado {hora}"

    cabecera = f"<b>{I_LUGAR} {LUGAR}</b>   " + color(estado, C_TENUE)
    prevision = bloque_dias(d) if vista == "dias" else bloque_horas(d)
    pie = color("<small>rueda: horas/días · clic: actualizar · clic dcho: AEMET</small>", C_TENUE)
    # El pie va en 'small' (≈0,83 veces el ancho normal)
    ancho = max([len(visible(l)) for l in [cabecera, *prevision]] + [len(visible(pie)) * 0.83])
    lineas = [
        cabecera,
        "",
        *centrar(bloque_actual(d), ancho),
        "",
        *prevision,
        "",
        pie,
    ]
    clases = [cat, "dia" if a["is_day"] else "noche"] + (["sin-conexion"] if sin_conexion else [])
    return {
        "text": f"{icono}  {round(a['temperature_2m'])}°C",
        "alt": desc,
        "tooltip": color("\n".join(lineas), C_TEXTO),
        "class": clases,
    }


def texto_hyprlock(d):
    """Texto plano para la pantalla de bloqueo (hyprlock no interpreta este marcado)."""
    a = d["current"]
    desc, _, icono = tiempo(a["weather_code"], a["is_day"])
    return "\n".join([
        f"{I_LUGAR} {LUGAR}",
        f"{icono}  {desc}",
        f"{round(a['temperature_2m'])}°C (sensación {round(a['apparent_temperature'])}°C)",
        f"{I_VIENTO} {round(a['wind_speed_10m'])} km/h   {I_HUMEDAD} {a['relative_humidity_2m']} %",
    ]) + "\n"


def main(args):
    if args[:1] == ["--vista"] and len(args) > 1 and args[1] in ("horas", "dias"):
        CACHE.mkdir(parents=True, exist_ok=True)
        VISTA.write_text(args[1])
        return
    datos, sin_conexion = obtener(forzar="--forzar" in args)
    if datos:
        tmp = HYPRLOCK.with_suffix(".tmp")
        tmp.write_text(texto_hyprlock(datos), encoding="utf-8")
        tmp.replace(HYPRLOCK)
    print(json.dumps(salida(datos, sin_conexion), ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main(sys.argv[1:])
