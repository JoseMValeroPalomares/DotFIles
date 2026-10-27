-- NOTA: ESTO NO ES CARGADO por Hyprland
-- Esta aqui solo como guia si quieres hacerlo manualmente
-- El archivo que deberias editar es ~/.config/hypr/workspaces.lua
-- ya que ese es el que se carga (require) con las reglas de workspace reales
-- usa nwg-displays para manejar tus reglas de workspace

-- Puedes definir reglas de workspace para lograr comportamientos especificos por workspace.
-- Por ejemplo, puedes definir un workspace donde todas las ventanas se dibujen sin bordes ni gaps.

-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Asignar un workspace a un monitor concreto. Los de abajo son solo ejemplos
-- hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "2", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "3", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "4", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "5", monitor = "DP-2" })
-- hl.workspace_rule({ workspace = "6", monitor = "DP-2" })
-- hl.workspace_rule({ workspace = "7", monitor = "DP-2" })
-- hl.workspace_rule({ workspace = "8", monitor = "DP-2" })


-- ejemplos de reglas (de la wiki)
-- hl.workspace_rule({ workspace = "3", no_rounding = true, decorate = false })
-- hl.workspace_rule({ workspace = "name:coding", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, no_border = true, monitor = "DP-1" })
-- hl.workspace_rule({ workspace = "8", border_size = 8 })
-- hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })
-- hl.workspace_rule({ workspace = "name:gaming", monitor = "desc:Chimei Innolux Corporation 0x150C", default = true })
-- hl.workspace_rule({ workspace = "5", on_created_empty = "[float] firefox" })
-- hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
