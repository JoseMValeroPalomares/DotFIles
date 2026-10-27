-- Default Keybinds
-- visit https://wiki.hypr.land/Configuring/Basics/Binds/ for more info


-- /* ---- ✴️ Variables ✴️ ---- */ --
local mainMod = "SUPER"
local Paths = require("configs.Paths")
local scriptsDir = Paths.scripts
local userScriptsDir = Paths.userScripts

-- Settings for User defaults apps - set tu terminal y file manager por defecto en ese archivo.
-- term, edit, files y searchEngine vienen de UserConfigs/01_UserDefaults.lua
-- y debe definir (globales o "return") las variables `term` y `files` usadas más abajo.
require("UserConfigs.01_UserDefaults")


---- STANDARD ----
-- Common shortcuts

-- hl.bind(mainMod .. " + " .. mainMod .. "_L", hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun -modi drun,filebrowser,run,window")) -- Super Key to Launch rofi menu
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill -x rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "app launcher" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd('xdg-open "https://"'), { description = "open default browser" })

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(scriptsDir .. "/OverviewToggle.sh"), { description = "desktop overview" }) -- alterna quickshell o ags overview (intenta QS primero, luego AGS)
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill -x rofi || true && ags -t 'overview'"), { description = "ags overview" })
-- hl.bind(mainMod .. " + A", hl.dsp.event("quickshell:overviewToggle"), { description = "Quickshell overview" })
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(term), { description = "Open terminal" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(files), { description = "file manager" })


-- FEATURES / EXTRAS
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(scriptsDir .. "/ThemeChanger.sh"), { description = "Global theme switcher using Wallust" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(scriptsDir .. "/TurboToggle.sh"), { description = "toggle Intel turbo boost" })
-- La ayuda antes estaba en H, comentada porque H ahora es Rofibeats
-- hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"), { description = "help / cheat sheet" })
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"), { description = "refresh bar and menus" })
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"), { description = "emoji menu" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("~/.local/bin/screenshot-ocr"), { description = "screenshot to text (OCR)" })

-- hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("rofi -show window"), { description = "window switcher" })
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("/bin/mi_script_captura.sh"), { description = "custom screenshot script" })

hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"), { description = "toggle blur" })

hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"), { description = "game / power saving mode" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("superproductivity --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-gpu"), { description = "open super productivity" })

-- Alterna dwindle/master en Lua (ChangeLayout.sh usaba `hyprctl keyword`, que no funciona con config Lua)
hl.bind(mainMod .. " + ALT + L", function()
    local layout = hl.get_config("general.layout") == "master" and "dwindle" or "master"
    hl.config({ general = { layout = layout } })
    hl.exec_cmd('notify-send -e -u low -i "$HOME/.config/swaync/images/ja.png" " ' .. layout:gsub("^%l", string.upper) .. ' Layout"')
end, { description = "toggle master/dwindle layout" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"), { description = "clipboard manager" })

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "fullscreen" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "maximize window" })
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float(), { description = "Float current window" })
-- Si hay alguna ventana en mosaico, flota todas; si ya flotan todas, las devuelve al mosaico
hl.bind(mainMod .. " + ALT + SPACE", function()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local wins = hl.get_workspace_windows(ws.name)
    local anyTiled = false
    for _, w in ipairs(wins) do
        if not w.floating then anyTiled = true break end
    end
    local action = anyTiled and "enable" or "disable"
    for _, w in ipairs(wins) do
        hl.dispatch(hl.dsp.window.float({ action = action, window = "address:" .. w.address }))
    end
end, { description = "Float all windows" })
-- Terminal desplegable: se abre la primera vez que se pulsa y luego se muestra/oculta.
-- Vive en special:dropterm; la animación specialWorkspaceIn/Out (animations/macOS.lua) la hace caer desde arriba.
-- Tamaño y posición: regla "dropterm" en UserConfigs/WindowRules.lua
-- Si se mueve a otro escritorio (o monitor), ese pasa a ser su sitio: la tecla la esconde en
-- special:dropterm y la vuelve a sacar allí. El sitio se guarda en un archivo para sobrevivir a
-- `hyprctl reload`; se olvida al abrir una nueva. En move, `follow = false` = silent (el sufijo
-- " silent" no vale: crea un especial con ese nombre); sin él, muestra el destino y le da el foco.
local DROPTERM_HOME = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-dropterm-home"

local function droptermHome(value)
    if value == nil then
        local f = io.open(DROPTERM_HOME, "r")
        if not f then return nil end
        local ws = f:read("l")
        f:close()
        return (ws and ws ~= "") and ws or nil
    end
    local f = io.open(DROPTERM_HOME, "w")
    if f then
        f:write(value)
        f:close()
    end
end

hl.bind(mainMod .. " + SHIFT + Return", function()
    local wins = hl.get_windows({ class = "kitty-dropterm" })
    if #wins == 0 then
        droptermHome("")
        hl.exec_cmd("kitty --class kitty-dropterm", { workspace = "special:dropterm" })
        return
    end
    local w = wins[1]
    local win = "address:" .. w.address
    local home = droptermHome()
    if w.workspace and w.workspace.name ~= "special:dropterm" then
        -- Está fuera de su especial: se recuerda dónde y se esconde
        local ws = w.workspace.special and w.workspace.name or tostring(w.workspace.id)
        droptermHome(ws)
        hl.dispatch(hl.dsp.window.move({ workspace = "special:dropterm", window = win, follow = false }))
    elseif home then
        -- Escondida pero con sitio propio: vuelve allí con el foco
        hl.dispatch(hl.dsp.window.move({ workspace = home, window = win }))
    else
        hl.dispatch(hl.dsp.workspace.toggle_special("dropterm"))
    end
end, { description = "DropDown terminal" })


-- Desktop zooming / magnifier
local zoom = require("configs.Zoom")
hl.bind(mainMod .. " + SHIFT + mouse_up", function() zoom(2) end, { description = "zoom in" })

hl.bind(mainMod .. " + SHIFT + mouse_down", function() zoom(0.5) end, { description = "zoom out" })
-- Zoom fino: pasos pequeños para un acercamiento fluido
hl.bind(mainMod .. " + CTRL + mouse_up", function() zoom(1.25) end, { description = "zoom in (fino)" })
hl.bind(mainMod .. " + CTRL + mouse_down", function() zoom(0.8) end, { description = "zoom out (fino)" })


-- Waybar / Bar related
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"), { description = "toggle waybar on/off" })
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"), { description = "waybar styles menu" })
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"), { description = "waybar layout menu" })


-- Night light toggle (Hyprsunset)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(scriptsDir .. "/Hyprsunset.sh toggle"), { description = "toggle night light" })


-- FEATURES / EXTRAS (UserScripts)
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(userScriptsDir .. "/RofiBeats.sh"), { description = "online music (Rofibeats)" })
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(userScriptsDir .. "/WallpaperSelect.sh"), { description = "select wallpaper" })
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd(userScriptsDir .. "/WallpaperEffects.sh"), { description = "wallpaper effects" })
hl.bind(mainMod .. " + CTRL + U", hl.dsp.exec_cmd(userScriptsDir .. "/HyprlockBackground.sh"), { description = "lockscreen background" })
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(userScriptsDir .. "/WallpaperRandom.sh"), { description = "random wallpaper" })
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "toggle active window opacity" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"), { description = "search keybinds" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"), { description = "animations menu" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"), { description = "web search (rofi)" })
-- Desactivado: solo hay distribución "us" (input.kb_layout en configs/SystemSettings.lua). Descomentar al añadir otra.
-- hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/KeyboardLayout.sh switch"), { locked = true, non_consuming = true, description = "switch keyboard layout globally" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(userScriptsDir .. "/RofiCalc.sh"), { description = "calculator" })


-- Move current workspace to monitors (left right up or down)
hl.bind(mainMod .. " + CTRL + F9", hl.dsp.workspace.move({ monitor = "l" }), { description = "move workspace to left monitor" })
hl.bind(mainMod .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }), { description = "move workspace to right monitor" })
hl.bind(mainMod .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }), { description = "move workspace to up monitor" })
hl.bind(mainMod .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }), { description = "move workspace to down monitor" })


---- SYSTEM ----
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "exit Hyprland" })
hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "close active window" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"), { description = "Terminate active process" })
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"), { description = "lock screen" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"), { description = "powermenu" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "notification panel" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scriptsDir .. "/Quick_Settings.sh"), { description = "Quick settings menu" })


-- Master Layout
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"), { description = "remove master" })
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"), { description = "add master" })
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })


-- Dwindle Layout
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "toggle split (dwindle)" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "toggle pseudo (dwindle)" })


-- Funciona en cualquier layout (Master o Dwindle)
-- El split ratio antes estaba en M, comentado porque M ahora es Night Light
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"), { description = "set split ratio 0.3" })


-- Cycle windows; si es flotante, traer al frente
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "cycle next window" })
hl.bind("ALT + Tab", hl.dsp.window.alter_zorder({ mode = "top" }), { description = "bring active to top" })


-- Special Keys / Hot Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"), { repeating = true, locked = true, description = "volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"), { repeating = true, locked = true, description = "volume down" })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc-precise"), { repeating = true, locked = true, description = "volume up precise" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec-precise"), { repeating = true, locked = true, description = "volume down precise" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true, description = "toggle mic mute" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"), { locked = true, description = "toggle mute" })
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "sleep" })
hl.bind("XF86Rfkill", hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"), { locked = true, description = "airplane mode" })


-- Media controls con teclas del teclado
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true, description = "play" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"), { locked = true, description = "next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"), { locked = true, description = "previous track" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true, description = "stop" })


-- Screenshot keybindings NOTE: puede que necesites pulsar la tecla Fn también
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "screenshot now" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "screenshot (area)" })
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"), { description = "screenshot in 5s" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "screenshot in 10s" })
hl.bind("ALT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "screenshot active window" })


-- Mi propio script de screenshot
hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("/bin/mi_script_captura.sh"), { description = "custom screenshot script" })


-- Screenshot con swappy (otra herramienta de captura)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy"), { description = "screenshot (swappy)" })


-- Resize windows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "resize left (-50)" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "resize right (+50)" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "resize up (-50)" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "resize down (+50)" })


-- Move windows
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }), { description = "move window left" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }), { description = "move window right" })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }), { description = "move window up" })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }), { description = "move window down" })


-- Swap windows (conserva pantalla completa / maximizado, ver configs/WindowSwap.lua)
local swapWindow = require("configs.WindowSwap")
hl.bind(mainMod .. " + ALT + left", function() swapWindow("l") end, { description = "swap window left" })
hl.bind(mainMod .. " + ALT + right", function() swapWindow("r") end, { description = "swap window right" })
hl.bind(mainMod .. " + ALT + up", function() swapWindow("u") end, { description = "swap window up" })
hl.bind(mainMod .. " + ALT + down", function() swapWindow("d") end, { description = "swap window down" })
-- Teclado 60 % (las flechas necesitan FN, y FN+SUPER bloquea SUPER): ALT derecho = izquierda, CTRL derecho = derecha
hl.bind(mainMod .. " + ALT + Alt_R", function() swapWindow("l") end, { description = "swap window left (Alt der.)" })
hl.bind(mainMod .. " + ALT + Control_R", function() swapWindow("r") end, { description = "swap window right (Ctrl der.)" })


-- Group
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "toggle group" })


-- Navegar dentro de un grupo
hl.bind(mainMod .. " + Tab", hl.dsp.group.next(), { description = "Change Group Forward" })
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next(), { description = "change active in group" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev(), { description = "Change Group Back" })


-- Mover ventana dentro/fuera de un grupo
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ into_group = "l" }), { description = "Move left into group" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ into_group = "r" }), { description = "Move Right into group" })
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ out_of_group = true }), { description = "Move active out of group" })


-- Intento de mover dinámicamente en ventana agrupada / desagrupada
-- No me funciona DW 11/26/25
-- hl.bind(mainMod .. " + right", hl.dsp.exec_cmd([[bash -c 'if hyprctl activewindow -j | jq -e "((.grouped | type) == \"boolean\") or (.address == (.grouped[-1] // empty))" >/dev/null 2>&1; then hyprctl dispatch movefocus r; else hyprctl dispatch changegroupactive f; fi']]), { description = "focus right" })
-- hl.bind(mainMod .. " + left", hl.dsp.exec_cmd([[bash -c 'if hyprctl activewindow -j | jq -e "((.grouped | type) == \"boolean\") or (.address == (.grouped[0] // empty))" >/dev/null 2>&1; then hyprctl dispatch movefocus l; else hyprctl dispatch changegroupactive b; fi']]), { description = "focus left" })


-- Move focus con mainMod + flechas
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }), { description = "focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }), { description = "focus right" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }), { description = "focus up" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }), { description = "focus down" })


-- Workspaces relacionado
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "m+1" }), { description = "next workspace" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "previous workspace" })


-- Special workspace
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special" }), { description = "move to special workspace" })
hl.bind(mainMod .. " + Z", hl.dsp.workspace.toggle_special(""), { description = "toggle special workspace" })


-- Los siguientes usan códigos de tecla para soportar mejor distintas distribuciones de teclado
-- 1 es code:10, 2 es code 11, etc
-- Cambiar workspaces con mainMod + [0-9]
hl.bind(mainMod .. " + code:10", hl.dsp.focus({ workspace = 1 }), { description = "workspace 1" })
hl.bind(mainMod .. " + code:11", hl.dsp.focus({ workspace = 2 }), { description = "workspace 2" })
hl.bind(mainMod .. " + code:12", hl.dsp.focus({ workspace = 3 }), { description = "workspace 3" })
hl.bind(mainMod .. " + code:13", hl.dsp.focus({ workspace = 4 }), { description = "workspace 4" })
hl.bind(mainMod .. " + code:14", hl.dsp.focus({ workspace = 5 }), { description = "workspace 5" })
hl.bind(mainMod .. " + code:15", hl.dsp.focus({ workspace = 6 }), { description = "workspace 6" })
hl.bind(mainMod .. " + code:16", hl.dsp.focus({ workspace = 7 }), { description = "workspace 7" })
hl.bind(mainMod .. " + code:17", hl.dsp.focus({ workspace = 8 }), { description = "workspace 8" })
hl.bind(mainMod .. " + code:18", hl.dsp.focus({ workspace = 9 }), { description = "workspace 9" })
hl.bind(mainMod .. " + code:19", hl.dsp.focus({ workspace = 10 }), { description = "workspace 10" })


-- Mover ventana activa y seguirla al workspace mainMod + SHIFT [0-9]
hl.bind(mainMod .. " + SHIFT + code:10", hl.dsp.window.move({ workspace = 1, follow = true }), { description = "move to workspace 1" })
hl.bind(mainMod .. " + SHIFT + code:11", hl.dsp.window.move({ workspace = 2, follow = true }), { description = "move to workspace 2" })
hl.bind(mainMod .. " + SHIFT + code:12", hl.dsp.window.move({ workspace = 3, follow = true }), { description = "move to workspace 3" })
hl.bind(mainMod .. " + SHIFT + code:13", hl.dsp.window.move({ workspace = 4, follow = true }), { description = "move to workspace 4" })
hl.bind(mainMod .. " + SHIFT + code:14", hl.dsp.window.move({ workspace = 5, follow = true }), { description = "move to workspace 5" })
hl.bind(mainMod .. " + SHIFT + code:15", hl.dsp.window.move({ workspace = 6, follow = true }), { description = "move to workspace 6" })
hl.bind(mainMod .. " + SHIFT + code:16", hl.dsp.window.move({ workspace = 7, follow = true }), { description = "move to workspace 7" })
hl.bind(mainMod .. " + SHIFT + code:17", hl.dsp.window.move({ workspace = 8, follow = true }), { description = "move to workspace 8" })
hl.bind(mainMod .. " + SHIFT + code:18", hl.dsp.window.move({ workspace = 9, follow = true }), { description = "move to workspace 9" })
hl.bind(mainMod .. " + SHIFT + code:19", hl.dsp.window.move({ workspace = 10, follow = true }), { description = "move to workspace 10" })
hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = true }), { description = "move to previous workspace" })
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1", follow = true }), { description = "move to next workspace" })


-- Mover ventana activa a un workspace en silencio mainMod + CTRL [0-9]
hl.bind(mainMod .. " + CTRL + code:10", hl.dsp.window.move({ workspace = 1, follow = false }), { description = "move silently to workspace 1" })
hl.bind(mainMod .. " + CTRL + code:11", hl.dsp.window.move({ workspace = 2, follow = false }), { description = "move silently to workspace 2" })
hl.bind(mainMod .. " + CTRL + code:12", hl.dsp.window.move({ workspace = 3, follow = false }), { description = "move silently to workspace 3" })
hl.bind(mainMod .. " + CTRL + code:13", hl.dsp.window.move({ workspace = 4, follow = false }), { description = "move silently to workspace 4" })
hl.bind(mainMod .. " + CTRL + code:14", hl.dsp.window.move({ workspace = 5, follow = false }), { description = "move silently to workspace 5" })
hl.bind(mainMod .. " + CTRL + code:15", hl.dsp.window.move({ workspace = 6, follow = false }), { description = "move silently to workspace 6" })
hl.bind(mainMod .. " + CTRL + code:16", hl.dsp.window.move({ workspace = 7, follow = false }), { description = "move silently to workspace 7" })
hl.bind(mainMod .. " + CTRL + code:17", hl.dsp.window.move({ workspace = 8, follow = false }), { description = "move silently to workspace 8" })
hl.bind(mainMod .. " + CTRL + code:18", hl.dsp.window.move({ workspace = 9, follow = false }), { description = "move silently to workspace 9" })
hl.bind(mainMod .. " + CTRL + code:19", hl.dsp.window.move({ workspace = 10, follow = false }), { description = "move silently to workspace 10" })
hl.bind(mainMod .. " + CTRL + bracketleft", hl.dsp.window.move({ workspace = "-1", follow = false }), { description = "move silently to previous workspace" })
hl.bind(mainMod .. " + CTRL + bracketright", hl.dsp.window.move({ workspace = "+1", follow = false }), { description = "move silently to next workspace" })


-- Recorrer workspaces existentes con mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })


-- Move/resize windows con mainMod + LMB/RMB arrastrando
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "move window" }) -- NOTE: mouse:272 = click izquierdo
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "resize window" }) -- NOTE: mouse:273 = click derecho

