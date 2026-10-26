---@module 'hl'

-- -----------------------------------------------------
-- Animaciones: carga el preset elegido en el menú SUPER+SHIFT+A (scripts/Animations.sh)
-- -----------------------------------------------------
-- Presets en ~/.config/hypr/animations/*.lua; el elegido se guarda en UserConfigs/AnimationPreset.
-- Por defecto, o si el preset falla, se usan las animaciones estilo macOS (animations/macOS.lua).

local Paths = require("configs.Paths")
local DIR = Paths.animations .. "/"
local STATE = Paths.userConfigs .. "/AnimationPreset"
local DEFAULT = "macOS"

local preset = DEFAULT
local f = io.open(STATE, "r")
if f then
    preset = (f:read("l") or ""):match("^%s*(.-)%s*$")
    f:close()
    if preset == "" then preset = DEFAULT end
end

local ok, err = pcall(dofile, DIR .. preset .. ".lua")
if not ok then
    hl.notification.create({ text = "Animaciones: no se pudo cargar '" .. preset .. "', uso " .. DEFAULT, timeout = 5000 })
    print(err)
    dofile(DIR .. DEFAULT .. ".lua")
end
