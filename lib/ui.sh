# shellcheck shell=bash
# Menús: gum si está, si no fzf, y si no un menú numerado con read

# choose_many "Título" "preseleccionados (separados por espacio)" opción1 opción2...
# Cada opción es "nombre|descripción". Devuelve los nombres elegidos, uno por línea.
choose_many() {
    local title=$1 preselected=$2; shift 2
    local -a opts=("$@") labels=() picked=()
    local o name i
    for o in "${opts[@]}"; do labels+=("${o%%|*} — ${o#*|}"); done

    if has gum; then
        local -a sel=()
        for o in "${opts[@]}"; do
            name=${o%%|*}
            [[ " $preselected " == *" $name "* ]] && sel+=("$name — ${o#*|}")
        done
        local IFS=,
        gum choose --no-limit --header="$title" --selected="${sel[*]}" "${labels[@]}" | sed 's/ — .*//'
        return
    fi
    if has fzf; then
        printf '%s\n' "${labels[@]}" |
            fzf --multi --height=80% --reverse --prompt="$title > " \
                --header='Tab: marcar · Ctrl-A: todos · Enter: aceptar' --bind='ctrl-a:select-all' |
            sed 's/ — .*//'
        return
    fi
    printf '\n%s%s%s\n' "$C_B" "$title" "$C_0" >&2
    for i in "${!labels[@]}"; do
        name=${opts[$i]%%|*}
        local flag=' '
        [[ " $preselected " == *" $name "* ]] && flag='*'
        printf '  %2d) [%s] %s\n' "$((i + 1))" "$flag" "${labels[$i]}" >&2
    done
    local ans
    read -r -p "  Números separados por espacios (Enter = los marcados con *, 'todo' = todos): " ans
    if [[ -z $ans ]]; then
        for o in "${opts[@]}"; do
            name=${o%%|*}
            [[ " $preselected " == *" $name "* ]] && picked+=("$name")
        done
    elif [[ $ans == todo ]]; then
        for o in "${opts[@]}"; do picked+=("${o%%|*}"); done
    else
        for i in $ans; do
            [[ $i =~ ^[0-9]+$ ]] && ((i >= 1 && i <= ${#opts[@]})) && picked+=("${opts[$((i - 1))]%%|*}")
        done
    fi
    ((${#picked[@]})) && printf '%s\n' "${picked[@]}"
    return 0
}

# choose_one "Título" opción1 opción2... (opciones "clave|texto"); devuelve la clave
choose_one() {
    local title=$1; shift
    local -a opts=("$@") labels=()
    local o
    for o in "${opts[@]}"; do labels+=("${o#*|}"); done
    local choice=""
    if has gum; then
        choice=$(gum choose --header="$title" "${labels[@]}")
    elif has fzf; then
        choice=$(printf '%s\n' "${labels[@]}" | fzf --height=40% --reverse --prompt="$title > ")
    else
        printf '\n%s%s%s\n' "$C_B" "$title" "$C_0" >&2
        local PS3="  Elige un número: "
        select choice in "${labels[@]}"; do [[ -n $choice ]] && break; done
    fi
    for o in "${opts[@]}"; do
        [[ ${o#*|} == "$choice" ]] && { printf '%s\n' "${o%%|*}"; return 0; }
    done
    return 1
}
