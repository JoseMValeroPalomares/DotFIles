-- For window rules and layerrules
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more

-- This file is used to add or overwrite window rules
-- This file will not be modified during dotfiles updates


-- ── terminal desplegable (SUPER+SHIFT+Return) ────────────────
-- 65 % del monitor, centrada en horizontal y al 10 % desde arriba
hl.window_rule({
    name = "dropterm",
    match = { class = "^(kitty-dropterm)$" },
    float = true,
    suppress_event = "maximize", -- kitty pide abrirse maximizado y anularía size/move
    -- Sin animación propia: si estaba escondida en el otro monitor, cruzaba volando hasta este.
    -- La entrada/salida la sigue haciendo specialWorkspaceIn/Out (animations/macOS.lua).
    no_anim = true,
    size = "monitor_w*0.65 monitor_h*0.65",
    move = "monitor_w*0.175 monitor_h*0.1",
})

-- ── terminal normal (SUPER+Return) ───────────────────────────
-- kitty pide abrirse maximizada: tapaba las demás ventanas hasta abrir la siguiente.
-- Se ignora la petición y entra en mosaico; SUPER+CTRL+F sigue maximizando a mano.
hl.window_rule({
    name = "kitty-no-maximize",
    match = { class = "^(kitty)$" },
    suppress_event = "maximize",
})

-- ── kitty: el aspecto lo decide solo el foco ─────────────────
-- Sustituye a la vendor "tag terminal → 0.9 0.7" (aquí se carga después y gana).
-- Con foco 1.0, sin foco 0.9, pantalla completa 1.0: igual en mosaico, flotante o SUPER+F.
-- Se multiplica por background_opacity de kitty.conf (0.55). Sin dim: el foco ya se nota
-- por la opacidad y el borde.
hl.window_rule({
    name = "kitty-focus-look",
    match = { class = "^(kitty|kitty-dropterm)$" },
    opacity = "1.0 0.9 1.0",
    no_dim = true,
})

-- ── swaync (notificaciones y centro de control) ──────────────
-- El CSS de GTK4 no puede desenfocar el fondo: el cristal lo pone Hyprland.
-- ignore_alpha evita desenfocar las zonas transparentes alrededor de las tarjetas.
for _, ns in ipairs({ "swaync-notification-window", "swaync-control-center" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true })
    hl.layer_rule({ match = { namespace = ns }, ignore_alpha = 0.3 })
    hl.layer_rule({ match = { namespace = ns }, animation = "slide right" })
end

-- ── wlogout (menú de energía, Super + L) ─────────────────────
-- Entra con un fundido (el desenfoque global está desactivado: el CSS oscurece el fondo).
hl.layer_rule({ match = { namespace = "logout_dialog" }, animation = "fade" })
