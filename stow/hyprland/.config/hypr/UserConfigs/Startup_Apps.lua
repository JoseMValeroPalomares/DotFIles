-- ### Aplicaciones Personales ###

hl.on("hyprland.start", function()
    -- Arrancar Super Productivity minimizado (si la app lo permite) o en segundo plano
    -- hl.exec_cmd("superproductivity --enable-features=UseOzonePlatform --ozone-platform=wayland")

    hl.exec_cmd("mcontrolcenter")

    -- Thunar en segundo plano: SUPER+E abre al instante y gestiona montajes automáticos
    hl.exec_cmd("thunar --daemon")

    hl.exec_cmd("zen-browser")

    -- Si usas alguna otra app como Telegram o Discord:
    -- hl.exec_cmd("telegram-desktop -startintray")
    -- hl.exec_cmd("discord --start-minimized")
end)