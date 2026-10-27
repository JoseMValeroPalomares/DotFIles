#!/usr/bin/env bash
# /* Calculator (using qalculate) and rofi */
# /* Submitted by: https://github.com/JosephArmas */
# Calculadora con teclado (SUPER+C). rofi en «modo script»: al pulsar una tecla rofi vuelve a llamar a este
# script SIN cerrar la ventana (sin parpadeo). La pantalla muestra la operación y el resultado en vivo.
#  · Clic o Intro sobre una tecla la añade · «=» calcula, copia y guarda en el historial · Esc = salir
#  · También se puede escribir: coma decimal (3,5 * 2), «15% de 80», «10 km a mi»; si termina en «=», calcula
#  · Tras «=», un número empieza una cuenta nueva; un operador sigue con el resultado (como una calculadora)

# --- Configuración ---
rofi_theme="$HOME/.config/rofi/config-calc.rasi"
history_file="${XDG_STATE_HOME:-$HOME/.local/state}/rofi-calc/historial"   # "operación<TAB>resultado"
HISTORY_MAX=50
QALC=(qalc -s 'decimal comma on')
RS=$'\x1e'   # separador del estado que rofi nos devuelve en ROFI_DATA
SQRT='sqrt('
CONTINUES='^[-+*/^%)×÷−]'   # tras «=», solo un operador sigue con el resultado (en variable: «(» o «)» sueltos en [[ =~ ]] fallan)
INCOMPLETE='[-+*/^,(]$'   # operación a medias: sin resultado en vivo

# Teclado 5 × 5: etiqueta|acción (la acción llega en ROFI_INFO)
KEYS=(
    "C|clear"  "⌫|back"  "(|("     ")|)"       "÷|/"
    "7|7"      "8|8"     "9|9"     "%|%"       "×|*"
    "4|4"      "5|5"     "6|6"     "√|sqrt("   "−|-"
    "1|1"      "2|2"     "3|3"     "^|^"       "+|+"
    "0|0"      ",|,"     "π|pi"    "Ans|ans"   "=|eval"
)
ACTIVE="2,3,4,8,9,13,14,18,19,22,23"   # operadores y funciones: color de acento (filas de rofi, desde 0)
URGENT="24"                            # «=»

# Texto con marcado: escapar & < > (\& porque en bash 5.2 & = texto encontrado)
escape() { local s=${1//&/\&amp;}; s=${s//</\&lt;}; printf '%s' "${s//>/\&gt;}"; }

# Español → sintaxis de qalc: «15% de 80» → «15% * 80»; «… a X» / «… en X» / «… to X» al final → «… to -X»
normalize() {
    sed -E -e 's/%[[:space:]]+de[[:space:]]+/% * /g' \
           -e 's/[[:space:]]+(a|en|to)[[:space:]]+-?([^[:space:]]+)$/ to -\2/' <<< "$1"
}

# La operación como se ve en una calculadora
pretty() {
    local s="$1"
    s=${s//sqrt(/√(}; s=${s//pi/π}; s=${s//\*/ × }; s=${s//\// ÷ }; s=${s//+/ + }; s=${s//-/ − }
    printf '%s' "$s"
}

# calc <operación> → deja en $result el resultado y en $understood lo que entendió qalc
calc() {
    local out last
    out=$("${QALC[@]}" "$(normalize "$1")" 2>/dev/null)
    last=$(tail -n 1 <<< "$out")
    result="" understood=""
    if [[ "$last" =~ ^(.*)\ (=|≈)\ (.*)$ ]]; then
        understood="${BASH_REMATCH[1]}" result="${BASH_REMATCH[3]}"
    fi
}

save_history() {
    mkdir -p "${history_file%/*}"
    { printf '%s\t%s\n' "$1" "$2"; cat "$history_file" 2>/dev/null; } |
        awk -F'\t' '!seen[$1]++' | head -n "$HISTORY_MAX" > "$history_file.tmp" &&
        mv -f "$history_file.tmp" "$history_file"
}

# --- Arranque: abrir rofi en modo script con este mismo archivo ---
if [[ -z "${ROFI_RETV:-}" ]]; then
    pidof rofi >/dev/null && pkill -x rofi
    exec rofi -show calc -modi "calc:$(realpath "${BASH_SOURCE[0]}")" -config "$rofi_theme"
fi

# --- Modo script: estado anterior (operación, último resultado, «recién calculado») ---
IFS="$RS" read -r expr ans fresh <<< "${ROFI_DATA:-}"
note=""

# Tras «=», un número (o paréntesis, π, √, Ans) empieza de cero; un operador sigue con el resultado
start_new_if_fresh() { [[ "$fresh" == 1 ]] && expr=""; fresh=0; }

evaluate() {
    [[ -n "$expr" ]] || return
    calc "$expr"
    if [[ -z "$result" ]]; then
        note="No entiendo la operación"
        return
    fi
    printf '%s' "$result" | wl-copy
    save_history "$expr" "$result"
    note="Copiado · entendido como: $(escape "$understood")"
    expr="$result" ans="$result" fresh=1
}

case "$ROFI_RETV" in
    1)  # tecla pulsada
        case "${ROFI_INFO:-}" in
            clear) expr="" fresh=0 ;;
            back)  fresh=0
                   if [[ "$expr" == *"$SQRT" ]]; then expr="${expr%"$SQRT"}"
                   elif [[ "$expr" == *pi ]]; then expr="${expr%pi}"
                   else expr="${expr%?}"; fi ;;
            eval)  evaluate ;;
            ans)   start_new_if_fresh; expr+="$ans" ;;
            *)     # tras «=»: un operador sigue con el resultado; números, «(», π y √ empiezan de cero
                   if [[ "$ROFI_INFO" =~ $CONTINUES ]]; then fresh=0; else start_new_if_fresh; fi
                   expr+="$ROFI_INFO" ;;
        esac
        ;;
    2)  # texto escrito + Intro
        typed="$1"
        if [[ "$typed" =~ $CONTINUES ]]; then fresh=0; else start_new_if_fresh; fi
        if [[ "$typed" == *= ]]; then
            expr+="${typed%=}"
            evaluate
        else
            expr+="$typed"
        fi
        ;;
esac

# --- Pantalla: operación grande y, debajo, el resultado en vivo (o el aviso de copiado) ---
if [[ -z "$expr" ]]; then
    screen='<span size="xx-large" alpha="40%">0</span>'
else
    screen="<span size=\"xx-large\">$(escape "$(pretty "$expr")")</span>"
fi
if [[ -n "$note" ]]; then
    line2="$note"
elif [[ -n "$expr" ]]; then
    # Solo si la operación está completa: paréntesis cerrados y sin operador al final (si no, qalc da «= 0»)
    opened="${expr//[^(]/}" closed="${expr//[^)]/}"
    if (( ${#opened} == ${#closed} )) && ! [[ "$expr" =~ $INCOMPLETE ]]; then
        calc "$expr"
        line2="${result:+= $(escape "$result")}"
    fi
else
    line2="= calcula y copia · Esc sale"
fi
printf '\0message\x1f%s&#10;<span alpha="70%%">%s</span>\n' "$screen" "${line2:- }"
printf '\0data\x1f%s\n' "$expr$RS$ans$RS$fresh"
printf '\0markup-rows\x1ffalse\n\0keep-selection\x1ftrue\n\0no-custom\x1ffalse\n'
printf '\0active\x1f%s\n\0urgent\x1f%s\n' "$ACTIVE" "$URGENT"
for key in "${KEYS[@]}"; do
    printf '%s\0info\x1f%s\n' "${key%%|*}" "${key#*|}"
done
