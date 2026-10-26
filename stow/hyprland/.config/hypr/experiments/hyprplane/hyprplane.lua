-- EXPERIMENTO hyprplane + parche Lua (HarryC913/hyprplane @ 3aa8a1f + experiments/hyprplane-lua.patch)
-- Plano infinito SOLO en el workspace 10 (HDMI): sus ventanas flotan y se arrastra todo el plano con
-- el botón central. El resto de workspaces siguen con tu dwindle de siempre.
--
-- Cargar solo en esta sesión: ~/.config/hypr/experiments/hyprplane-load.sh
-- Quitar del todo:            ~/.config/hypr/experiments/hyprplane-uninstall.sh
-- Atajos: ver experiments/README.md

local WS = 10
local hp = hl.plugin.hyprplane
if not hp then return end -- plugin sin cargar: no hacer nada

local function on_canvas()
    local ws = hl.get_active_workspace()
    return ws ~= nil and hp.is_canvas(ws.id)
end

-- Las ventanas que lleguen al 10 desde otro workspace (SHIFT+SUPER+0) también pasan al plano, en su sitio;
-- el plugin las apunta para devolverlas al mosaico al apagar el plano o descargarlo
local function float_tiled_on_canvas()
    hp.adopt(WS)
end

-- El 10 es plano en cuanto existe; enter() no hace nada si ya lo es
local function ensure_canvas()
    if hl.get_workspace(WS) then hp.enter(WS) end
end

if not rawget(_G, "__exp_hyprplane") then
    _G.__exp_hyprplane = true

    hl.on("workspace.active", function() pcall(ensure_canvas) end)
    hl.on("workspace.created", function() pcall(ensure_canvas) end)
    hl.on("window.open", function() pcall(ensure_canvas) end) -- al crearse, el ws aún no es consultable
    hl.on("window.move_to_workspace", function() pcall(float_tiled_on_canvas) end)

    local mod = "SUPER + CTRL + SHIFT"
    local function canvas_only(fn)
        return function() if on_canvas() then fn() end end
    end

    -- Mover el plano con el teclado
    local STEP = 300
    for key, d in pairs({ left = { STEP, 0 }, right = { -STEP, 0 }, up = { 0, STEP }, down = { 0, -STEP } }) do
        hl.bind(mod .. " + " .. key, canvas_only(function() hp.pan(d[1], d[2]) end),
            { repeating = true, description = "[exp] plano: mover vista " .. key })
    end

    -- Traer todas las ventanas a la vista actual
    hl.bind(mod .. " + G", canvas_only(hp.gather), { description = "[exp] plano: reunir ventanas" })

    -- Saltar a la ventana N (1 = la más grande; números del minimapa)
    for n = 1, 10 do
        hl.bind(mod .. " + code:" .. (n + 9), canvas_only(function() hp.jump(n) end),
            { description = "[exp] plano: ir a ventana " .. n })
    end

    -- Probar el plano en el workspace actual (encender/apagar)
    hl.bind(mod .. " + C", function()
        local ws = hl.get_active_workspace()
        if ws then hp.toggle(ws.id) end
    end, { description = "[exp] plano: alternar en este workspace" })
end

ensure_canvas()
