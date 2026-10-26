# Inventario de scripts y menús (Fase 1 · 2026-10-21)

Leyenda de «Llamado por»: **A** = atajo (configs/Keybinds.lua, Laptops.lua), **W** = Waybar activa (`configs/2`),
**w** = solo en módulos de Waybar que la barra activa NO carga, **I** = autoarranque, **QS** = Ajustes rápidos,
**S** = otro script, **H** = hyprlock/hypridle, **—** = nadie.
SC = avisos de shellcheck (`-S warning`), E = errores. Propuesta = clasificación de la Fase 2 (pendiente de confirmar lo marcado con ?).

## ~/.config/hypr/scripts

| Script | Fecha | Tamaño | Llamado por | SC | Propuesta |
|---|---|---|---|---|---|
| AirplaneMode.sh | 02-27 | 0,5 K | A | 0 | revisar (fase 3) |
| Animations.sh | 10-20 | 1,8 K | A, QS | 0 | mantener (rehecho en 2.7) |
| Battery.sh | 02-27 | 0,3 K | — | 0 | **archivar** (Waybar usa el módulo nativo `battery`) |
| Brightness.sh | 02-27 | 1,5 K | A (teclas), W (backlight) | 1 | mejorar; ¿fusionar con `~/.local/bin/brillo`? |
| BrightnessKbd.sh | 02-27 | 1,2 K | A (teclas) | 1 | mejorar |
| ChangeBlur.sh | 10-20 | 0,6 K | A, W (power) | 0 | mantener |
| ClipManager.sh | 10-21 | 1,4 K | A | 0 | mantener |
| GameMode.sh | 10-20 | 2,7 K | A, QS | 0 | mantener |
| Hypridle.sh | 02-27 | 0,8 K | w | 0 | ? archivar (no está en la barra activa) |
| HyprlockCheck.sh | 10-21 | 1,4 K | manual | 0 | mantener |
| HyprlockMonitor.sh | 10-21 | 1,0 K | H | 0 | mantener |
| Hyprsunset.sh | 02-27 | 2,8 K | I, A | 0 | revisar |
| KeyBinds.sh + keybinds_menu.py + KeyBinds.rasi | 10-20 | 7,8 K | A, QS | 0 | mantener (2.8) |
| KeyboardLayout.sh | 02-27 | 3,6 K | A | 1E+3 | ? arreglar o archivar (solo hay distribución `us`) |
| KeyHints.sh | 10-20 | 3,2 K | A | 0 | mantener |
| KillActiveProcess.sh | 02-27 | 0,5 K | A | 0 | revisar |
| Kitty_themes.sh | 02-27 | 5,1 K | QS | 0 | **archivar** (usuario) + quitar de QS |
| Kool_Quick_Settings.sh | 10-20 | 5,6 K | A | 1 | mejorar (quitar kitty y sddm) |
| LockScreen.sh | 10-21 | 0,3 K | A, H, wlogout, swaync | 0 | mantener |
| MediaCtrl.sh | 02-27 | 1,2 K | A | 0 | revisar |
| MonitorsConfig.sh | 10-20 | 3,0 K | QS | 0 | mantener |
| OverviewToggle.sh | 10-20 | 0,8 K | A | 0 | mantener |
| Polkit.sh | 04-11 | 1,1 K | I | 1 | revisar |
| Polkit-NixOS.sh | 02-27 | 0,9 K | — | 0 | **archivar** (NixOS) |
| PortalHyprland.sh | 02-27 | 0,9 K | — | 0 | **archivar** |
| QuickSettings.rasi | 10-20 | 1,1 K | S | — | mantener (fase 5) |
| Refresh.sh | 10-21 | 1,3 K | A, S ×7 | 1 | mejorar |
| RefreshNoWaybar.sh | 10-20 | 1,1 K | S (solo WallpaperAutoChange) | 0 | **archivar** junto con WallpaperAutoChange |
| RofiEmoji.sh | 10-20 | 89 K | A | 1E | **mejorar** (usuario: lo quiere mejor) |
| RofiSearch.sh | 10-20 | 1,2 K | — (¡sin atajo!) | 0 | ? el usuario dice que lo usa |
| RofiThemeSelector.sh | 02-27 | 5,6 K | A, QS | 1 | mantener → fusionar con -modified |
| RofiThemeSelector-modified.sh | 02-27 | 6,2 K | A | 2E+4 | fusionar en RofiThemeSelector.sh |
| ScreenShot.sh | 02-27 | 4,2 K | A | 0 | revisar |
| sddm_wallpaper.sh | 02-27 | 5,5 K | QS | 5 | **archivar** (sddm desinstalado) + quitar de QS |
| Sounds.sh | 02-27 | 2,6 K | S | 0 | revisar |
| spotify.sh | 10-21 | 0,8 K | H | 0 | mantener |
| Tak0-Autodispatch.sh | 02-27 | 9,6 K | — | 1 | **archivar** (ya decidido en P5) |
| Tak0-Per-Window-Switch.sh | 10-20 | 3,5 K | A (SHIFT+ALT) | 5 | ? archivar (solo hay `us`: no hace nada) |
| ThemeChanger.sh | 10-20 | 5,1 K | A | 0 | mantener |
| TouchPad.sh | 10-20 | 1,2 K | A | 0 | mantener |
| TurboToggle.sh | 10-21 | 0,9 K | A | 0 | mantener |
| UptimeNixOS.sh | 02-27 | 0,8 K | — | 0 | **archivar** (NixOS) |
| UserConfigsSwitcher.sh | 02-27 | 2,0 K | — | 1 | **archivar** |
| Volume.sh | 02-27 | 4,8 K | A, W (pulseaudio/mpris) | 7 | **arreglar** (el que más avisos tiene) |
| WallustSwww.sh | 10-21 | 4,1 K | S | 0 | mantener |
| WaybarCava.sh | 02-27 | 1,3 K | w | 0 | ? no está en la barra activa |
| WaybarLayout.sh / WaybarStyles.sh / WaybarScripts.sh | 10-20 | 5 K | A, W | 0 | mantener |
| Wlogout.sh | 10-21 | 1,1 K | A, W, swaync | 0 | mantener |

## ~/.config/hypr/UserScripts

| Script | Fecha | Llamado por | SC | Propuesta |
|---|---|---|---|---|
| HyprlockBackground.sh / HyprlockStats.sh | 10-21 | A, H | 0 | mantener |
| RofiBeats.sh | 02-27 | A | 0 | mejorar (uso ocasional) |
| RofiCalc.sh | 10-20 | A | 0 | mantener |
| WallpaperAutoChange.sh | 02-27 | — | 0 | **archivar** (usuario) |
| WallpaperEffects.sh | 10-20 | A, S | 2 | mejorar |
| WallpaperRandom.sh | 02-27 | A | 1 | mejorar |
| WallpaperSelect.sh | 10-20 | A, I, S | 1E+4 | **arreglar** (`$array[i]` sin llaves) |
| ZshChangeTheme.sh | 10-20 | A | 1 | **archivar** (usuario) + quitar atajo |

## Fuera de hypr

| Archivo | Llamado por | Propuesta |
|---|---|---|
| waybar/scripts/clima.py | W, LockScreen.sh | mantener (tiene su propio plan en waybar/) |
| waybar/scripts/contraste.py | — | **archivar** en `waybar/legacy/` (usuario) |
| ~/.local/bin/brillo | swaync, wlogout, keybinds_menu.py | revisar frente a Brightness.sh |
| ~/.local/bin/screenshot-ocr | A (SUPER+S) | revisar |

## ~/.config/rofi (git desde f4c43ea)

- Activo: `config.rasi` → `themes/KooL_style-8.rasi`. Los otros 19 temas solo se usan desde el selector de temas.
  12 importan wallust; 8 tienen colores fijos.
- `config-*.rasi`: uno por menú. Sin uso: `config-keybinds.rasi` (KeyBinds usa `hypr/scripts/KeyBinds.rasi`),
  `config-Monitors.rasi` y `0-shared-fonts.rasi`. Se archivan con su script: `config-kitty-theme.rasi` y `config-zsh-theme.rasi`.
  Copia: `config-clipboard.rasi.bak-2026-10-21`.

---

# Resultado final (Fase 6 · 2026-10-21)

**Archivado en `legacy/`** (nada borrado): sddm_wallpaper, ZshChangeTheme, WallpaperAutoChange, RefreshNoWaybar, Polkit-NixOS,
UptimeNixOS, PortalHyprland, UserConfigsSwitcher, Battery, Tak0-Per-Window-Switch, Tak0-Autodispatch, WaybarCava,
BrightnessKbd, RofiThemeSelector (+ -modified). waybar/legacy: contraste.py. rofi/legacy: 9 temas sin wallust,
config-zsh-theme, config-keybinds, config-Monitors, 0-shared-fonts, config-rofi-theme, copia .bak del portapapeles.

**Rehechos** (comportamiento revisado, probados con programas falsos y/o en real):
WallpaperSelect (archivo exacto, 795 → 52 ms), WallpaperRandom (cuelgue con el daemon caído), WallpaperEffects (15 efectos
con vista previa y caché), Volume (1 llamada a pamixer, ~190 → ~10 ms), Brightness, ~/.local/bin/brillo (sin sudo),
Refresh (no mata swaync), Sounds, ScreenShot, AirplaneMode (wifi + Bluetooth), MediaCtrl, KillActiveProcess, Polkit,
RofiEmoji (cuadrícula, categorías, recientes), RofiBeats (solo su mpv, menú con estado), RofiCalc (teclado en modo script),
~/.local/bin/screenshot-ocr (en memoria, ×2).

**Retocados**: WallustSwww y Startup_Apps (awww), KeyHints, Hyprsunset, Kool_Quick_Settings (escape, entradas),
WaybarLayout/WaybarStyles, KeyBinds, RofiSearch (atajo SUPER+SHIFT+O), ThemeChanger, Kitty_themes (textos).

**Sin cambios** (revisados, correctos): Animations, ChangeBlur, ClipManager, GameMode, HyprlockCheck/Monitor/Background/Stats,
KeyBinds+keybinds_menu.py, LockScreen, MonitorsConfig, OverviewToggle, TouchPad, TurboToggle, WaybarScripts, Wlogout,
spotify, Hypridle (solo barras alternativas), clima.py.

**Atajos**: quitados SUPER+SHIFT+O (zsh, ahora búsqueda web), SHIFT+ALT (Tak0), ALT+SHIFT (KeyboardLayout, comentado hasta
que haya otra distribución), SUPER+CTRL+SHIFT+R y SUPER+CTRL+R (selectores de tema), teclas de luz del teclado. 162 atajos.

**Validación**: shellcheck (nivel warning) limpio salvo KeyboardLayout.sh (desactivado) y un SC2155 inocuo en
Kool_Quick_Settings; todos los scripts referenciados por atajos, Waybar, hypridle y hyprlock existen y son ejecutables;
`hyprctl reload` sin errores; 15 menús y 12 temas de rofi sin errores.

**Pendiente**: módulo `custom/updater` de 4 barras alternativas de Waybar (SummitSplit) apunta a Distro_update.sh
(archivado el 2026-10-20 como off_Distro_update.sh); (emojis en español: descartado por el usuario).
