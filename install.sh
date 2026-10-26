#!/usr/bin/env bash
# Instalador de los dotfiles de Jose (Arch Linux + Hyprland).
# Modular e idempotente: se puede ejecutar las veces que haga falta.
set -euo pipefail

DOTFILES=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)
export DOTFILES
# shellcheck source=lib/load.sh
source "$DOTFILES/lib/load.sh"

usage() {
    cat <<EOF
${C_B}Uso:${C_0} ./install.sh [modo] [opciones]

${C_B}Modos${C_0} (si no indicas ninguno, aparece un menú):
  --first-time, --full   Instalación completa (yo reinstalando): todos los componentes,
                         todos los paquetes y el hardware autodetectado.
  --custom               Personalizado: menú para elegir componentes y hardware.
  --minimal              Solo shell + terminal + editor: ${MINIMAL_COMPONENTS[*]}

${C_B}Opciones:${C_0}
  --only a,b,c           Instala solo estos componentes (sin menú).
  --skip a,b,c           Excluye estos componentes.
  --hardware LISTA       auto | none | lista (intel,amd,nvidia,laptop,bluetooth,msi).
  --no-packages          No instala paquetes: solo configs (enlaces, semillas y post).
  --dry-run              Muestra lo que haría sin cambiar nada.
  -y, --yes              Responde que sí a todo (sin preguntas).
  --list                 Lista los componentes.
  -h, --help             Esta ayuda.

${C_B}Ejemplos:${C_0}
  ./install.sh --first-time --dry-run
  ./install.sh --only zsh,kitty --no-packages
  ./install.sh --custom
  ./install.sh --first-time --skip spicetify,apps --yes

Las copias de lo que se reemplaza van a ~/.dotfiles-backup/<fecha>/
EOF
}

MODE="" ONLY="" SKIP="" HW_ARG="" NO_PACKAGES=0
while (($#)); do
    case $1 in
        --first-time | --full) MODE=full ;;
        --custom) MODE=custom ;;
        --minimal) MODE=minimal ;;
        --only) ONLY=${2:?--only necesita una lista}; shift ;;
        --only=*) ONLY=${1#*=} ;;
        --skip) SKIP=${2:?--skip necesita una lista}; shift ;;
        --skip=*) SKIP=${1#*=} ;;
        --hardware) HW_ARG=${2:?--hardware necesita un valor}; shift ;;
        --hardware=*) HW_ARG=${1#*=} ;;
        --no-packages) NO_PACKAGES=1 ;;
        --dry-run | -n) DRY_RUN=1 ;;
        -y | --yes) ASSUME_YES=1 ;;
        --list) list_components; exit 0 ;;
        -h | --help) usage; exit 0 ;;
        *) usage >&2; die "Opción desconocida: $1" ;;
    esac
    shift
done
export DRY_RUN ASSUME_YES NO_PACKAGES

((EUID != 0)) || die "No lo ejecutes como root: usa tu usuario (se pedirá sudo cuando haga falta)"
[[ -f /etc/arch-release ]] || log_warn "No parece Arch Linux; continúa bajo tu responsabilidad"

split_list() { tr ',' '\n' <<<"$1" | sed 's/[[:space:]]//g' | grep -v '^$' || true; }

SELECTED=()
HARDWARE=()

# --- Modo interactivo si no se indicó nada ---
if [[ -z $MODE && -z $ONLY ]]; then
    [[ -t 0 ]] || { usage >&2; die "Sin terminal interactiva: indica un modo"; }
    MODE=$(choose_one "¿Qué quieres hacer?" \
        "full|Instalación completa (mi equipo, todo como lo tengo)" \
        "custom|Personalizado (elijo componentes y hardware)" \
        "minimal|Mínimo (zsh + kitty + nano)" \
        "exit|Salir") || exit 1
    [[ $MODE == exit ]] && exit 0
fi

# --- Componentes ---
if [[ -n $ONLY ]]; then
    mapfile -t SELECTED < <(split_list "$ONLY")
else
    case $MODE in
        full) SELECTED=("${COMPONENTS[@]}") ;;
        minimal) SELECTED=("${MINIMAL_COMPONENTS[@]}") ;;
        custom)
            opts=()
            for c in "${COMPONENTS[@]}"; do opts+=("$c|${COMP_DESC[$c]}"); done
            mapfile -t SELECTED < <(choose_many "Componentes a instalar" "${COMPONENTS[*]}" "${opts[@]}")
            ;;
    esac
fi
if [[ -n $SKIP ]]; then
    mapfile -t skip_list < <(split_list "$SKIP")
    filtered=()
    for c in "${SELECTED[@]}"; do
        [[ " ${skip_list[*]} " == *" $c "* ]] || filtered+=("$c")
    done
    SELECTED=("${filtered[@]}")
fi
for c in "${SELECTED[@]}"; do
    is_component "$c" || die "Componente desconocido: $c (mira ./install.sh --list)"
done
((${#SELECTED[@]})) || die "No hay componentes seleccionados"

# --- Hardware ---
mapfile -t DETECTED < <(detect_hardware)
if [[ -z $HW_ARG ]]; then
    case $MODE in
        full) HW_ARG=auto ;;
        custom) HW_ARG=ask ;;
        *) HW_ARG=none ;;
    esac
fi
case $HW_ARG in
    auto) HARDWARE=("${DETECTED[@]}") ;;
    none) HARDWARE=() ;;
    ask)
        describe_hardware
        opts=()
        for h in "${HW_PROFILES[@]}"; do opts+=("$h|${HW_DESC[$h]}"); done
        mapfile -t HARDWARE < <(choose_many "Hardware (marcado = autodetectado)" "${DETECTED[*]}" "${opts[@]}")
        ;;
    *) mapfile -t HARDWARE < <(split_list "$HW_ARG") ;;
esac
for h in "${HARDWARE[@]}"; do
    [[ " ${HW_PROFILES[*]} " == *" $h "* ]] || die "Perfil de hardware desconocido: $h"
done
if [[ $MODE == custom ]] && ! ((NO_PACKAGES)) && ! ((DRY_RUN)); then
    confirm "¿Instalar también los paquetes de cada componente?" s || NO_PACKAGES=1
fi

# --- Plan ---
log_step "Plan"
log_info "Repo: $DOTFILES"
log_info "Componentes (${#SELECTED[@]}): ${SELECTED[*]}"
log_info "Hardware: ${HARDWARE[*]:-ninguno} ${C_DIM}(detectado: ${DETECTED[*]:-nada})${C_0}"
((NO_PACKAGES)) && log_info "Sin paquetes (--no-packages)"
((DRY_RUN)) && log_info "${C_YEL}Simulación: no se cambiará nada${C_0}"
for c in "${SELECTED[@]}"; do
    for r in ${COMP_RECOMMENDS[$c]:-}; do
        [[ " ${SELECTED[*]} " == *" $r "* ]] && continue
        component_present "$r" && continue
        log_warn "$c funciona mejor con «$r» (no seleccionado). No fallará, pero algo puede no responder."
    done
done
confirm "¿Continuar?" s || exit 0

# --- Ejecución ---
SUMMARY_FILE=$(mktemp)
export SUMMARY_FILE
SUDO_KEEPALIVE_PID=""
cleanup() {
    [[ -n $SUDO_KEEPALIVE_PID ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    rm -f "$SUMMARY_FILE"
}
trap cleanup EXIT

needs_sudo=0
((NO_PACKAGES)) || needs_sudo=1
((${#HARDWARE[@]})) && needs_sudo=1
[[ " ${SELECTED[*]} " == *" system "* ]] && needs_sudo=1
((needs_sudo)) && sudo_keepalive

if ((NO_PACKAGES)); then
    has stow || die "Falta stow (instálalo o ejecuta sin --no-packages)"
    detect_aur_helper || true
else
    bootstrap
fi

# Ejecuta cada paso en un subshell con set -e: si falla, se apunta y se sigue con el resto
run_step() { # run_step "etiqueta" función args...
    local label=$1 rc
    shift
    set +e
    (
        set -e
        "$@"
    )
    rc=$?
    set -e
    if ((rc == 0)); then mark ok "$label"; else mark err "$label (código $rc)"; log_error "Falló: $label"; fi
}

install_hardware() {
    log_step "Hardware: $1 — ${HW_DESC[$1]}"
    if ((NO_PACKAGES)); then
        log_info "Perfil de hardware omitido con --no-packages"
        return 0
    fi
    "hw_$1"
}

run_hardware() {
    local h
    for h in "${HARDWARE[@]}"; do run_step "hardware:$h" install_hardware "$h"; done
}

# Orden: base -> hardware (drivers) -> resto de componentes
[[ " ${SELECTED[*]} " == *" base "* ]] && run_step base install_component base
run_hardware
for c in "${COMPONENTS[@]}"; do
    [[ $c != base && " ${SELECTED[*]} " == *" $c "* ]] || continue
    run_step "$c" install_component "$c"
done

# --- Resumen ---
log_step "Resumen"
for kind in ok skip err; do
    case $kind in
        ok) title="${C_GRN}Instalado / al día${C_0}" ;;
        skip) title="${C_YEL}Omitido${C_0}" ;;
        err) title="${C_RED}Errores${C_0}" ;;
    esac
    mapfile -t items < <(grep "^$kind|" "$SUMMARY_FILE" | cut -d'|' -f2- || true)
    ((${#items[@]})) || continue
    printf '  %s%s%s\n' "$C_B" "$title" "$C_0"
    printf '    - %s\n' "${items[@]}"
done
not_selected=()
for c in "${COMPONENTS[@]}"; do
    [[ " ${SELECTED[*]} " == *" $c "* ]] || not_selected+=("$c")
done
((${#not_selected[@]})) && log_info "No seleccionados: ${not_selected[*]}"
[[ -d $BACKUP_DIR ]] && log_info "Backup de lo reemplazado: ${BACKUP_DIR/#$HOME/\~}"
((DRY_RUN)) && log_info "Era una simulación: no se ha cambiado nada."
if grep -q '^err|' "$SUMMARY_FILE"; then
    exit 1
fi
log_ok "Listo. Cierra sesión y vuelve a entrar (o reinicia si instalaste drivers)."
