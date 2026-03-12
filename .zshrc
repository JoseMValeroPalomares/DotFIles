# ==============================================================================
# CONFIGURACIÓN BASE OH-MY-ZSH
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="1mitema"

# ==============================================================================
# CONFIGURACIÓN DE TMUX (Auto-arranque)
# ==============================================================================
# Inicia Tmux automáticamente al abrir la terminal
ZSH_TMUX_AUTOSTART=true
# FALSO para que NO se conecte a la sesión anterior, sino que cree una nueva
ZSH_TMUX_AUTOCONNECT=false
# Comentamos el nombre por defecto para que Tmux las numere solo (0, 1, 2...)
# ZSH_TMUX_DEFAULT_SESSION_NAME="Principal"

# ==============================================================================
# PLUGINS
# ==============================================================================
plugins=(
    git
    archlinux
    tmux                      # Gestiona el autoarranque de tmux de forma segura
    sudo                      # Pulsa ESC dos veces para poner 'sudo' al principio
    extract                   # Comando 'extract archivo.zip/tar/rar' lo extrae todo
    zsh-autosuggestions
    zsh-syntax-highlighting   # ¡Ojo! Este siempre debe ir el ÚLTIMO de la lista
)

source $ZSH/oh-my-zsh.sh

# ==============================================================================
# HISTORIAL "NIVEL DIOS"
# ==============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt appendhistory
setopt SHARE_HISTORY          # Comparte el historial entre diferentes pestañas/paneles en tiempo real
setopt HIST_IGNORE_ALL_DUPS   # Si repites un comando, borra el viejo y guarda el nuevo
setopt HIST_IGNORE_SPACE      # Si pones un espacio antes de un comando, NO lo guarda (ideal para contraseñas)
setopt HIST_REDUCE_BLANKS     # Limpia espacios en blanco extra en los comandos guardados

# ==============================================================================
# OPCIONES EXTRA DE ZSH
# ==============================================================================
setopt AUTO_CD                # Escribe solo el nombre de una carpeta para entrar a ella (sin poner 'cd')
setopt INTERACTIVE_COMMENTS   # Permite pegar comandos de internet que tengan '#' al final sin que dé error

# ==============================================================================
# ALIASES VIP
# ==============================================================================
# lsd (Reemplazos de ls)
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Navegación rápida
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Comandos más seguros y con feedback
alias cp='cp -iv'             # Pide confirmación antes de sobrescribir
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'       # Crea carpetas padre si no existen

# Actualización rápida en Arch Linux (Pacman)
alias update='sudo pacman -Syu'

# ==============================================================================
# INTEGRACIONES (FZF y scripts)
# ==============================================================================
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

# Reemplazo de cat por bat con resaltado de sintaxis
alias cat='bat'


# ==============================================================================
# FZF + BAT: BUSCADOR BORROSO CON VISTA PREVIA
# ==============================================================================

# 1. Usar 'fd' por defecto (más rápido, ignora archivos ocultos inútiles y respeta .gitignore)
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden --exclude .git'

# 2. Configurar la vista previa para usar 'bat' a todo color
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=right:60%"
export FZF_ALT_C_OPTS="--preview 'lsd --tree --depth 2 --color=always {}' --preview-window=right:60%"

# 3. Asignar 'Ctrl+F' a la búsqueda de archivos
bindkey '^f' fzf-file-widget



# Ruleta Rusa de Fastfetch
LOGO_DIR="$HOME/.config/fastfetch/logos"
if [ -d "$LOGO_DIR" ]; then
    # Elige un archivo al azar de la carpeta
    RANDOM_LOGO=$(find "$LOGO_DIR" -type f | shuf -n 1)

    # Ejecuta fastfetch pasando SOLO la ruta del logo y tu config
    fastfetch --logo "$RANDOM_LOGO" -c "$HOME/.config/fastfetch/config-compact.jsonc"
else
    # Si por lo que sea no encuentra la carpeta, carga el normal
    fastfetch -c "$HOME/.config/fastfetch/config-compact.jsonc"
fi


alias reloj='kitty -o font_size=25 tty-clock -c -C 7 -b -d "%d/%m/%Y" & disown'


# Función corregida para evitar el error de "bad pattern"
reloj_setup() {
    # 1. Btop a la izquierda
    hyprctl dispatch exec "[workspace 3]" "kitty --class btop_ws3 btop"
    
    # Pausa para asegurar que btop tome la izquierda
    sleep 0.3
    
    # 2. Reloj (Arriba a la derecha)
    hyprctl dispatch exec "[workspace 3]" "kitty -o font_size=25 --class reloj_ws3 tty-clock -c -C 7 -b -d '%d/%m/%Y'"
    
    # 3. Bonsái (Abajo a la derecha)
    hyprctl dispatch exec "[workspace 3]" "kitty --class bonsai_ws3 cbonsai -l -i -w 10 -b 1 -m '                        -STAY FOCUSED.           -STAY HARD.             -NO EXCUSES.       -JUST WORK.       -CUMTRIBUTE'"
}

alias setup3='reloj_setup'
export PATH=$PATH:/home/jose/.spicetify
