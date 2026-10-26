---@module 'hl'

-- -----------------------------------------------------
-- Animaciones estilo macOS con la fluidez de Hyprland
-- -----------------------------------------------------
-- Idea: todo desacelera suave al llegar (ease-out), sin rebotes.
-- Abrir tarda algo más que cerrar, como en macOS.
-- speed = décimas de segundo (3 = 300 ms). Todo nativo, sin coste extra de CPU.

hl.config({
    animations = {
        enabled = true,
    },
})

-- Curvas
-- macOut: ease-out exponencial. Arranque rápido, aterrizaje muy suave (aperturas)
hl.curve("macOut", {
    type = "bezier",
    points = { { 0.16, 1 }, { 0.3, 1 } },
})
-- macMove: ease-out quint. Para mover/reordenar ventanas y el zoom
hl.curve("macMove", {
    type = "bezier",
    points = { { 0.22, 1 }, { 0.36, 1 } },
})
-- macIn: acelera al salir. Para cierres y desapariciones, que deben ser breves
hl.curve("macIn", {
    type = "bezier",
    points = { { 0.3, 0 }, { 0.8, 0.15 } },
})
-- macSpaces: ease-in-out suave. Para el cambio de escritorio (como Mission Control)
hl.curve("macSpaces", {
    type = "bezier",
    points = { { 0.25, 0.8 }, { 0.25, 1 } },
})

-- Base para lo que no se define abajo (antes heredaba 800 ms)
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "macOut" })

-- Ventanas: aparecen escalando desde el 92 % + fundido, se van rápido
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "macOut", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "macIn", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "macMove", style = "slide" })

-- Fundidos
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "macOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "macIn" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "macOut" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "macOut" })

-- Capas (rofi, swaync, waybar): leve zoom + fundido, como los menús de macOS
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "macOut", style = "popin 95%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.8, bezier = "macIn", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "macOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "macIn" })

-- Bordes: transición de color al cambiar el foco (sin animar el ángulo en bucle)
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "macOut" })

-- Escritorios: deslizamiento horizontal como los Spaces de macOS
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "macSpaces", style = "slide" })
-- Special workspace / terminal desplegable: cae un poco desde arriba con fundido y se va
-- subiendo, más rápido. El % negativo invierte el sentido (por defecto entraría desde abajo).
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "macOut", style = "slidefadevert -8%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "macIn", style = "slidefadevert -8%" })

-- Zoom de escritorio (SUPER+SHIFT+rueda, gestos)
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "macMove" })
