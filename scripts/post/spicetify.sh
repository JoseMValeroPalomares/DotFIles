#!/usr/bin/env bash
# Spicetify: instala la CLI, temas y marketplace, ajusta permisos de /opt/spotify y aplica.
# También sirve tras una actualización de Spotify que rompe el parche:
#   ./scripts/post/spicetify.sh

SPICETIFY_BIN="$HOME/.spicetify/spicetify"
SPICETIFY_CFG="$HOME/.config/spicetify"

spicetify_cmd() { run "$SPICETIFY_BIN" "$@"; }

spicetify_install_cli() {
    if [[ -x $SPICETIFY_BIN ]]; then
        log_ok "Spicetify ya instalado ($("$SPICETIFY_BIN" -v 2>/dev/null || echo '?'))"
        return 0
    fi
    log_info "Descargando la última versión de spicetify-cli en ~/.spicetify"
    local tag ver tmp
    tag=$(curl -fsSL https://api.github.com/repos/spicetify/cli/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
    [[ -n $tag ]] || { log_error "No se pudo consultar la versión de spicetify"; return 1; }
    ver=${tag#v}
    tmp=$(mktemp -d)
    run curl -fsSL "https://github.com/spicetify/cli/releases/download/$tag/spicetify-$ver-linux-amd64.tar.gz" -o "$tmp/s.tgz"
    run mkdir -p "$HOME/.spicetify"
    run tar -xzf "$tmp/s.tgz" -C "$HOME/.spicetify"
    run chmod +x "$SPICETIFY_BIN"
    rm -rf "$tmp"
}

spicetify_assets() {
    git_clone_once https://github.com/spicetify/spicetify-themes.git "$SPICETIFY_CFG/Themes"
    if [[ -f $SPICETIFY_CFG/CustomApps/marketplace/index.js ]]; then
        log_ok "Marketplace ya instalado"
    else
        local tmp
        tmp=$(mktemp -d)
        run curl -fsSL https://github.com/spicetify/marketplace/releases/latest/download/marketplace.zip -o "$tmp/m.zip"
        run mkdir -p "$SPICETIFY_CFG/CustomApps"
        run unzip -qo "$tmp/m.zip" -d "$tmp"
        run rm -rf "$SPICETIFY_CFG/CustomApps/marketplace"
        run mv "$tmp/marketplace-dist" "$SPICETIFY_CFG/CustomApps/marketplace"
        rm -rf "$tmp"
    fi
}

# Spicetify necesita escribir en /opt/spotify. El paquete lo instala como root y cada
# actualización de Spotify restablece los permisos, por eso se comprueba siempre.
spicetify_permissions() {
    local dir=/opt/spotify
    if [[ -w $dir && -w $dir/Apps ]]; then
        log_ok "$dir es escribible por $USER"
        return 0
    fi
    log_warn "$dir no es escribible por $USER: Spicetify no puede parchear Spotify."
    log_info "Solución: hacer a $USER propietario de $dir (solo afecta a Spotify)."
    if confirm "¿Ejecutar 'sudo chown -R $USER: $dir'?" s; then
        run_sudo chown -R "$USER:" "$dir"
    else
        return 1
    fi
}

spicetify_configure() {
    # Misma configuración que el sistema original (referencia: scripts/spicetify/config-xpui.ini.ref)
    spicetify_cmd config \
        current_theme StarryNight color_scheme Base \
        inject_css 1 replace_colors 1 overwrite_assets 0 inject_theme_js 1 \
        check_spicetify_update 1 always_enable_devtools 0 \
        disable_sentry 1 disable_ui_logging 1 remove_rtl_rule 1 expose_apis 1 \
        sidebar_config 0 home_config 1 experimental_features 1
    if ! grep -qE '^custom_apps *= *.*marketplace' "$SPICETIFY_CFG/config-xpui.ini" 2>/dev/null; then
        spicetify_cmd config custom_apps marketplace
    fi
}

spicetify_apply() {
    # 1) normal  2) Spotify actualizado (backup viejo): restore + backup + apply
    # 3) backup roto: se borra el backup y se rehace. Las preguntas de spicetify se responden con "y".
    if ((DRY_RUN)); then
        spicetify_cmd backup apply
        return 0
    fi
    if { yes || true; } | "$SPICETIFY_BIN" -q backup apply; then
        return 0
    fi
    log_warn "backup apply falló (¿Spotify se ha actualizado?); probando restore backup apply"
    if { yes || true; } | "$SPICETIFY_BIN" -q restore backup apply; then
        return 0
    fi
    log_warn "Rehaciendo el backup desde cero"
    { yes || true; } | "$SPICETIFY_BIN" -q clear
    { yes || true; } | "$SPICETIFY_BIN" -q backup apply
}

post_spicetify() {
    if ! pkg_installed spotify && [[ ! -d /opt/spotify ]]; then
        log_warn "Spotify no está instalado: se omite Spicetify"
        mark skip "spicetify: Spotify no instalado"
        return 0
    fi
    spicetify_install_cli || return 1
    if [[ ! -f $SPICETIFY_CFG/config-xpui.ini ]] && ! ((DRY_RUN)); then
        "$SPICETIFY_BIN" >/dev/null 2>&1 || true   # genera la config por defecto
    fi
    spicetify_assets
    spicetify_permissions || { mark skip "spicetify: sin permisos en /opt/spotify"; return 0; }
    spicetify_configure
    if pgrep -x spotify >/dev/null; then
        log_info "Spotify está abierto: se reiniciará al aplicar"
    fi
    spicetify_apply || { mark err "spicetify: no se pudo aplicar"; return 1; }
    log_ok "Spicetify aplicado (tema StarryNight)"
}

if [[ ${BASH_SOURCE[0]} == "$0" && -z ${DOTFILES_LOADED:-} ]]; then
    DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)
    # shellcheck source=lib/load.sh
    source "$DOTFILES/lib/load.sh"
    standalone post_spicetify "$@"
fi
