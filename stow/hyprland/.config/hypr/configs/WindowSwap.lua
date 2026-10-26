---@module 'hl'

-- Intercambiar ventanas conservando la pantalla completa / maximizado de cada una.
-- Hyprland no intercambia una ventana a pantalla completa: se quita, se intercambia y se restaura.
-- Uso: local swap = require("configs.WindowSwap"); swap("l") | "r" | "u" | "d"

local MODES = { [1] = "maximized", [2] = "fullscreen", [3] = "fullscreen" } -- valor de window.fullscreen

local function fullscreen(address, action, mode)
    hl.dispatch(hl.dsp.window.fullscreen({ window = "address:" .. address, action = action, mode = mode }))
end

return function(direction)
    local active = hl.get_active_window()
    if not active then return end

    -- Ventanas visibles (en cualquier monitor) a pantalla completa o maximizadas
    local saved = {}
    for _, w in ipairs(hl.get_windows()) do
        local mode = MODES[w.fullscreen]
        if mode and w.workspace and w.workspace.visible then
            saved[#saved + 1] = { address = w.address, mode = mode }
            fullscreen(w.address, "unset", mode)
        end
    end

    hl.dispatch(hl.dsp.focus({ window = "address:" .. active.address }))
    hl.dispatch(hl.dsp.window.swap({ direction = direction }))

    for _, s in ipairs(saved) do
        fullscreen(s.address, "set", s.mode)
    end
    hl.dispatch(hl.dsp.focus({ window = "address:" .. active.address }))
end
