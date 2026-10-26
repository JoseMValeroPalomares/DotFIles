-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */ --
-- Ver https://wiki.hypr.land/Configuring/Basics/Binds/ para mas ajustes de variables
-- Estos configs son principalmente para portatiles. Es un anexo a Keybinds.lua

local mainMod = "SUPER"
local Paths = require("configs.Paths")
local scriptsDir = Paths.scripts
local userConfigsDir = Paths.userConfigs

-- Lo de abajo es util cuando conectas tu portatil a una pantalla externa
-- Se sugiere editar esto para tu pantalla de portatil
-- De la WIKI: esto desactiva el monitor del portatil cuando se cierra la tapa.
-- consulta https://wiki.hypr.land/Configuring/Basics/Binds/#switches
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, preferred, auto, 1"'))
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, disable"'))


-- ADVERTENCIA! Usar este metodo tiene algunas salvedades!! USALO CON PRECAUCION!
-- CONTRAS de hacer esto: necesitas configurar tu wallpaper (SUPER W) y elegir wallpaper.
-- SALVEDAD! A veces el monitor principal del portatil NO tiene pantalla y necesita reconectar tu monitor externo
-- Un workaround es asegurarte de que antes de apagar el portatil, la TAPA este ABIERTA!!
-- Asegurate de comentar (poner -- en ambas lineas de switch) arriba
-- NOTA: la pantalla del portatil se genera en LaptopDisplay.lua
-- Esta parte se usa si no quieres que tu monitor principal del portatil se despierte al, por ejemplo, cambiar de wallpaper

-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('echo \'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })\' > ' .. userConfigsDir .. "/LaptopDisplay.lua"))
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd('echo \'hl.monitor({ output = "eDP-1", disabled = true })\' > ' .. userConfigsDir .. "/LaptopDisplay.lua"))

-- para la accion de la tapa del portatil (para borrar la ultima entrada)
-- hl.on("hyprland.start", function()
--     hl.exec_cmd('echo \'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })\' > ' .. userConfigsDir .. "/LaptopDisplay.lua")
-- end)

