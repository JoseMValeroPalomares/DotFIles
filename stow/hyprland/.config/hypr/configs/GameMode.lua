---@module 'hl'

-- Modo juego / ahorro de energía, reversible sin `hyprctl reload`.
-- Al activar se guardan los valores actuales; al desactivar se restauran tal cual.
-- La parte de perfil de energía (powerprofilesctl) y el menú viven en scripts/GameMode.sh.
-- Si Hyprland recarga la config con un modo activo, la config vuelve sola a la normalidad
-- y aquí solo se avisa al script para que restaure el perfil de energía.

local M = {}

local Paths = require("configs.Paths")
local SCRIPT = Paths.scripts .. "/GameMode.sh"
local STATE_FILE = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-gamemode"
local MONITORS_FILE = Paths.hypr .. "/monitors.lua"

-- Opciones que tocan los modos (y que se guardan/restauran)
local KEYS = {
    "animations.enabled",
    "decoration.shadow.enabled",
    "decoration.blur.enabled",
    "decoration.dim_inactive",
    "decoration.rounding",
    "general.gaps_in",
    "general.gaps_out",
    "general.border_size",
    "render.direct_scanout",
}

local PRESETS = {
    -- Juego: fuera todo lo que cuesta GPU o latencia, scanout directo en juegos a pantalla completa
    game = {
        ["animations.enabled"] = false,
        ["decoration.shadow.enabled"] = false,
        ["decoration.blur.enabled"] = false,
        ["decoration.dim_inactive"] = false,
        ["decoration.rounding"] = 0,
        ["general.gaps_in"] = 0,
        ["general.gaps_out"] = 0,
        ["general.border_size"] = 1,
        ["render.direct_scanout"] = 2,
    },
    -- Ahorro: menos trabajo de composición, pero se conserva el aspecto (gaps, bordes, esquinas)
    saver = {
        ["animations.enabled"] = false,
        ["decoration.shadow.enabled"] = false,
        ["decoration.blur.enabled"] = false,
        ["decoration.dim_inactive"] = false,
    },
}

-- Ventanas opacas mientras haya un modo activo (menos mezcla de capas)
local opaqueRule = hl.window_rule({
    name = "gamemode-opaque",
    match = { class = ".*" },
    opacity = "1.0 override 1.0 override",
    enabled = false,
})

local active = nil -- { mode = "game"|"saver", saved = { [key] = value } }

-- "a.b.c" = v  ->  { a = { b = { c = v } } }
local function nest(flat)
    local out = {}
    for key, value in pairs(flat) do
        local node = out
        local parts = {}
        for part in key:gmatch("[^.]+") do parts[#parts + 1] = part end
        for i = 1, #parts - 1 do
            node[parts[i]] = node[parts[i]] or {}
            node = node[parts[i]]
        end
        node[parts[#parts]] = value
    end
    return out
end

-- Pone todos los monitores a la frecuencia más cercana a `hz` que admitan en su resolución actual
local function set_refresh(hz)
    for _, m in ipairs(hl.get_monitors()) do
        local best
        for _, mode in ipairs(m.available_modes or {}) do
            if mode.width == m.width and mode.height == m.height
                and (not best or math.abs(mode.refresh_rate - hz) < math.abs(best.refresh_rate - hz)) then
                best = mode
            end
        end
        if best then
            hl.monitor({
                output = m.name,
                mode = string.format("%dx%d@%.3f", best.width, best.height, best.refresh_rate),
                position = m.x .. "x" .. m.y,
                scale = m.scale,
            })
        end
    end
end

function M.enable(mode, hz)
    local preset = PRESETS[mode]
    if not preset then return end
    if active then M.disable() end

    local saved = {}
    for _, key in ipairs(KEYS) do saved[key] = hl.get_config(key) end
    active = { mode = mode, saved = saved }

    hl.config(nest(preset))
    opaqueRule:set_enabled(true)
    hl.exec_scheduled_prop_refresh_immediately()
    if hz then set_refresh(hz) end
end

function M.disable()
    if not active then return end
    hl.config(nest(active.saved))
    opaqueRule:set_enabled(false)
    hl.exec_scheduled_prop_refresh_immediately()
    dofile(MONITORS_FILE) -- vuelve a aplicar tus monitores tal como están en monitors.lua
    active = nil
end

function M.status()
    return active and active.mode or "off"
end

-- Recarga con un modo activo: la config ya está restaurada, falta el perfil de energía
local f = io.open(STATE_FILE, "r")
if f then
    f:close()
    hl.exec_cmd(SCRIPT .. " --restore-profile")
end

return M
