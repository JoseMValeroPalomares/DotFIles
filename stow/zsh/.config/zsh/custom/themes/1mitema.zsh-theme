# ------------------------------------------------------------------------------
# TEMA ZSH: DEGRADADO ÍNDIGO/LAVANDA + SEPARADORES [/] [\] + CIERRE REDONDEADO
# ------------------------------------------------------------------------------

setopt prompt_subst

# --- CONFIGURACIÓN DE FORMAS (Nerd Fonts) ---
local SEP_SLASH=""       # Corte inclinado hacia adelante tipo /
local SEP_BACKSLASH=""   # Corte inclinado hacia atrás tipo \
local SEP_ROUND=""       # Borde redondeado (píldora)
local SEP_R=""           # Flecha derecha clásica (>)

# --- PALETA FUSIONADA: MOCHA + ÍNDIGO/ZAFIRO ---
local C_CRUST="#11111b"     # Crust (Fondo de texto)
local C_TEXT="#cdd6f4"      # Text (Texto claro)
local C_GREEN="#95d58f"     # Green (Fusión de éxitos para no ser tan brillante)
local C_RED="#e67b98"       # Red (Fusión de errores, rojo suave)
local C_SURFACE="#3b3e4f"   # Surface (Fusión de grises para la estructura)

# Degradado principal (Transición: Azul Zafiro -> Índigo -> Mauve -> Lavanda suave)
local C_GRAD1="#6a82c3"     # L1: Usuario (Índigo Azulado oscuro)
local C_GRAD2="#6d98cc"     # L1: IP (Zafiro medio)
local C_GRAD3="#a797e1"     # L2: Hora (Morado Zafiro / Mauve)
local C_GRAD4="#cdb6e7"     # L2: Directorio (Lavanda suave)

# --- FUNCIÓN: IP LOCAL ---
# Se cachea 15 s para no lanzar ip+awk en cada prompt
zmodload -F zsh/datetime p:EPOCHSECONDS
typeset -g _MYTHEME_IP="" _MYTHEME_IP_TS=0
get_local_ip() {
  if (( EPOCHSECONDS - _MYTHEME_IP_TS >= 15 )); then
    local -a route=(${=$(ip -4 route get 1.1.1.1 2>/dev/null)})
    local i=${route[(i)src]}
    _MYTHEME_IP=${route[i+1]}
    _MYTHEME_IP_TS=$EPOCHSECONDS
  fi
  print -rn -- "$_MYTHEME_IP"
}

# --- CONFIGURACIÓN DE GIT ---
ZSH_THEME_GIT_PROMPT_PREFIX=" %F{$C_GRAD4}⎇ %F{$C_TEXT}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{$C_RED}✘%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{$C_GREEN}✔%f"

SHOW_CMD_STATUS=0

mytheme_preexec() {
  SHOW_CMD_STATUS=1
}

mytheme_precmd() {
  local exit_code=$?

  # 1. RPROMPT (A la derecha)
  if [[ $SHOW_CMD_STATUS -eq 1 ]]; then
    if [[ $exit_code -eq 0 ]]; then
      RPROMPT="%F{$C_GREEN}✔%f"
    else
      RPROMPT="%F{$C_RED}✘ %F{$C_TEXT}[$exit_code]%f"
    fi
  else
    RPROMPT=""
  fi
  SHOW_CMD_STATUS=0

  # 2. SIMETRÍA
  local user_text=${(%):-%n}
  local time_text=${(%):-%T}
  
  local len_user=${#user_text}
  local len_time=${#time_text}
  local max_len=$(( len_user > len_time ? len_user : len_time ))
  
  local padded_user=${(l:$max_len:: :)user_text}
  local padded_time=${(l:$max_len:: :)time_text}
  get_local_ip >/dev/null; local current_ip=$_MYTHEME_IP

  # 3. CONSTRUCCIÓN DE CAJAS
  
  # LÍNEA 1: Usuario [/] IP [>]
  local l1_box1="%K{$C_GRAD1}%F{$C_CRUST} ${padded_user} "
  local l1_trans="%K{$C_GRAD2}%F{$C_GRAD1}${SEP_SLASH}"
  local l1_box2="%K{$C_GRAD2}%F{$C_CRUST} ${current_ip} "
  local l1_end="%k%F{$C_GRAD2}${SEP_R}%f"

  # LÍNEA 2: [Cuadrado] Hora [\] Directorio [ )]
  # Se eliminó la variable l2_start para que empiece de forma plana (cuadrada)
  local l2_box1="%K{$C_GRAD3}%F{$C_CRUST} ${padded_time} "
  local l2_trans="%K{$C_GRAD4}%F{$C_GRAD3}${SEP_BACKSLASH}"
  local l2_box2="%K{$C_GRAD4}%F{$C_CRUST} %~ "
  local l2_end="%k%F{$C_GRAD4}${SEP_ROUND}%f"

  local p_symbol="%F{$C_GRAD4}❯%f"

  # 4. ENSAMBLAJE FINAL
  # La Línea 2 ahora se pega directamente a la línea estructural de la terminal
  PROMPT="
%F{$C_SURFACE}╭─%f${l1_box1}${l1_trans}${l1_box2}${l1_end}\$(git_prompt_info)
%F{$C_SURFACE}╰─%f${l2_box1}${l2_trans}${l2_box2}${l2_end} ${p_symbol} "
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd mytheme_precmd
add-zsh-hook preexec mytheme_preexec