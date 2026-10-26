---@module 'hl'

-- Zoom de escritorio en Lua puro (sustituye a `hyprctl keyword`, que no funciona con config Lua)
-- Uso: local zoom = require("configs.Zoom"); zoom(2) acerca, zoom(0.5) aleja

local MIN, MAX = 1, 10 -- límites de cursor:zoom_factor

return function(multiplier)
    local current = math.max(MIN, tonumber(hl.get_config("cursor.zoom_factor")) or MIN)
    local target = math.min(MAX, math.max(MIN, current * multiplier))
    hl.config({ cursor = { zoom_factor = target } })
end
