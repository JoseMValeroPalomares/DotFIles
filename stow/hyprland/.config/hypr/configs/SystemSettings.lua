-- Default settings
-- Aqui pones tus propios ajustes, no se tocara durante update si se usa upgrade.sh

-- ver la wiki de Hyprland para mas info https://wiki.hypr.land/Configuring/Basics/Variables/
-- NOTA: decoración y animaciones están en UserConfigs/UserDecorations.lua y UserAnimations.lua

local scriptsDir = require("configs.Paths").scripts
local zoom = require("configs.Zoom")

hl.config({

    dwindle = {
        preserve_split = true,
        -- smart_split = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact = 0.5,
    },

    general = {
        resize_on_border = true,
        layout = "dwindle",
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,

        sensitivity = 0, -- sensibilidad del raton
        -- accel_profile = "", -- flat o adaptive o vacio significa el modo por defecto de libinput
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        float_switch_override_focus = false,

        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            clickfinger_behavior = false,
            middle_button_emulation = false,
            tap_to_click = true,
            drag_lock = false,
        },

        -- para dispositivos con touchdevice ie. pantalla tactil
        touchdevice = {
            enabled = true,
        },

        -- para tableta, ver el link de arriba para las variables correctas
        tablet = {
            transform = 0,
            left_handed = false,
        },
    },

    gestures = {
        -- Ajustes de la "fisica" y direccion logica del swipe, siguen siendo validos en 0.55+
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 2,
        mouse_move_enables_dpms = true,
        enable_swallow = true,
        swallow_regex = "^(kitty)$",
        focus_on_activate = false,
        initial_workspace_tracking = 0,
        middle_click_paste = false,
        enable_anr_dialog = true, -- Application not Responding (ANR)
        anr_missed_pings = 15, -- Umbral de ANR, el default de 1 es demasiado bajo
        allow_session_lock_restore = true, -- Evita crash de lockscreen al resumir de suspend
        -- Esto solo funciona con HL v0.53+
        on_focus_under_fullscreen = 1,
        -- 0 - Default, sin cambios
        -- 1 - La nueva ventana enfocada toma el fullscreen (como Alt-Tab de Windows)
        -- 2 - La nueva ventana enfocada se queda detras de la fullscreen
    },

    -- opengl = {
    --     nvidia_anti_flicker = true,
    -- },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    -- Puede ayudar cuando se escala y no se quiere pixelado
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = 0,
    },

    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = false, -- cambia a true si quieres desactivarlo
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
        zoom_detached_camera = false, -- con zoom, la vista sigue al ratón de forma continua
        zoom_rigid = false, -- seguimiento suave, no rígido
    },

    debug = {
        vfr = true,
    },

})


-- GESTOS 1:1 (sintaxis nueva vía hl.gesture)
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        zoom(1.5)
    end,
})

hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        zoom(1 / 1.5)
    end,
})

hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.exec_cmd(scriptsDir .. "/OverviewToggle.sh"))
    end,
})
