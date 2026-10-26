-- Rutas de la configuración, en un único sitio.
-- Uso: local Paths = require("configs.Paths")  →  Paths.scripts .. "/Script.sh"
local hypr = os.getenv("HOME") .. "/.config/hypr"

return {
    hypr = hypr,
    scripts = hypr .. "/scripts",
    userScripts = hypr .. "/UserScripts",
    userConfigs = hypr .. "/UserConfigs",
    animations = hypr .. "/animations",
}
