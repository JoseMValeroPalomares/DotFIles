-- Decoration Settings

-- Hyprland Wiki Links
-- Animation - https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- Decoration - https://wiki.hypr.land/Configuring/Basics/Variables/#decoration

-- Carga los colores generados por wallust
-- IMPORTANTE: wallust debe generar wallust-hyprland.lua (tabla Lua), no el .conf viejo.
-- Ver wallust-hyprland-template.txt para la plantilla necesaria.
local colors = require("wallust.wallust-hyprland")

hl.config({

    general = {
        border_size = 1,

        -- gaps_in = 2,
        -- gaps_out = 4,
        -- col = {
        --     active_border = colors.color12,
        --     inactive_border = colors.color10,
        -- },

        gaps_in = 3, -- Un pelin mas de espacio interior
        gaps_out = 4,
        col = {
            active_border = { colors = { colors.color13, colors.color15 }, angle = 45 },
            inactive_border = colors.color2,
        },
    },

    decoration = {
        rounding = 10,

        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.03,
        dim_special = 0.5,

        shadow = {
            enabled = false,
            range = 3,
            render_power = 1,

            color = colors.color12,
            -- color_inactive = colors.color10,
            color_inactive = 0x50000000,
        },

        blur = {
            enabled = false,
            size = 4,
            passes = 2,
            new_optimizations = true,
            xray = true,
            ignore_opacity = true,
            special = false,
            popups = false,
        },
    },

    group = {
        col = {
            border_active = colors.color15,
        },

        groupbar = {
            col = {
                active = colors.color0,
            },
        },
    },

})
