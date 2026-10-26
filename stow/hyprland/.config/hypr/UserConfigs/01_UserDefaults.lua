-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */ --

-- Este es un archivo donde pones tus apps por defecto, motor de busqueda por defecto, etc.

-- Define aqui tu editor preferido, descomenta y reinicia para que tenga efecto.
-- NOTA: esto se descomenta automaticamente si seleccionas neovim o vim como editor por defecto.
-- hl.env("EDITOR", "vim") -- editor por defecto

-- Define el editor de texto preferido para el KooL Quick Settings Menu (SUPER SHIFT E)
-- el script tomara el EDITOR por defecto y nano como fallback
-- IMPORTANTE: sin 'local' para que sea global y visible desde otros archivos (Keybinds.lua, etc.)
edit = os.getenv("EDITOR") or "nano"


-- Estas dos son usadas por Keybinds.lua y los modulos de Waybar
term = "kitty" -- Terminal
files = "thunar" -- Gestor de archivos


-- Motor de busqueda por defecto para Rofi Search (SUPER+SHIFT+O)
searchEngine = "https://www.google.com/search?q={}"
