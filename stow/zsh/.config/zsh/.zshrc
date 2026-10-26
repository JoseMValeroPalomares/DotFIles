# ==============================================================================
# TMUX (Auto-arranque, lo primero de todo)
# ==============================================================================
# Cada terminal abre una sesión nueva de tmux. Va antes que nada para que este
# primer zsh no cargue oh-my-zsh entero solo para lanzar tmux (que abre otro zsh).
# Mismas exclusiones que el plugin tmux; si tmux falla, sigue como shell normal.
if [[ -o interactive && -z $TMUX && -z $INSIDE_EMACS$EMACS$VIM$INTELLIJ_ENVIRONMENT_READER$ZED_TERM \
      && $ZSH_TMUX_AUTOSTARTED != true ]] && (( $+commands[tmux] )); then
    export ZSH_TMUX_AUTOSTARTED=true
    command tmux new-session && exit
fi

# ==============================================================================
# CONFIGURACIÓN BASE OH-MY-ZSH
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
# Tema y plugins propios fuera del repo de oh-my-zsh (versionados en ~/.config/zsh)
ZSH_CUSTOM="$HOME/.config/zsh/custom"
ZSH_THEME="1mitema"

# Caché de autocompletado fuera del $HOME (antes llenaba ~ de .zcompdump-*)
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$HOST-$ZSH_VERSION"
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"

# Sin compaudit en cada arranque (~15 ms): revisa permisos de las carpetas de
# completado, y aquí no hay ninguna insegura. Comprobarlo a mano: compaudit
ZSH_DISABLE_COMPFIX="true"

# Git más rápido en repos grandes: no mira archivos sin seguimiento para el ✘/✔
DISABLE_UNTRACKED_FILES_DIRTY="true"
# Actualizaciones de oh-my-zsh: avisa en vez de pararse a preguntar al abrir terminal
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 14

# El plugin tmux solo aporta sus alias (ta, ts, tl, tksv…): el arranque va arriba
ZSH_TMUX_AUTOSTART=false

# ==============================================================================
# PLUGINS
# ==============================================================================
# Autosugerencias: primero historial, luego completado; sin recalcular en cada tecla
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# you-should-use: tras un comando que tiene alias, te lo recuerda (en el lavanda del tema).
# cat/ls se ignoran: son reemplazos (bat/lsd) y avisaría cada vez que los escribes a mano.
YSU_MESSAGE_POSITION="after"
YSU_IGNORED_ALIASES=("cat" "ls")
YSU_MESSAGE_FORMAT=$'\e[38;2;167;151;225m󰌵 Tienes un %alias_type para «%command»: usa \e[1m%alias\e[0m'

plugins=(
    git
    archlinux
    tmux                      # Alias de tmux (el autoarranque está al principio)
    sudo                      # Pulsa ESC dos veces para poner 'sudo' al principio
    extract                   # Comando 'extract archivo.zip/tar/rar' lo extrae todo
    fzf-tab                   # Menú de Tab con buscador fzf (antes de autosuggestions)
    you-should-use            # Recuerda los alias que ya tienes
    zsh-autosuggestions
    zsh-syntax-highlighting   # ¡Ojo! Este siempre debe ir el ÚLTIMO de la lista
)

source $ZSH/oh-my-zsh.sh

# ==============================================================================
# PATH (sin duplicados aunque se recargue la shell o venga de .zprofile)
# ==============================================================================
typeset -U path PATH
path+=("$HOME/.local/bin" "$HOME/.spicetify")

# fnm (versiones de Node): la v22 por defecto va directa al PATH, sin ejecutar
# fnm al arrancar (~10 ms y una carpeta en /run/user por shell). La primera vez
# que escribes 'fnm' se carga su entorno completo (para 'fnm use' en un proyecto).
path=("${FNM_DIR:-$HOME/.local/share/fnm}/aliases/default/bin" $path)
fnm() { unfunction fnm; eval "$(command fnm env --shell zsh)"; fnm "$@" }

# ==============================================================================
# HISTORIAL "NIVEL DIOS"
# ==============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # Guarda fecha y duración de cada comando
setopt SHARE_HISTORY          # Comparte el historial entre diferentes pestañas/paneles en tiempo real
setopt HIST_IGNORE_ALL_DUPS   # Si repites un comando, borra el viejo y guarda el nuevo
setopt HIST_FIND_NO_DUPS      # Al buscar con flechas no muestra el mismo comando dos veces
setopt HIST_IGNORE_SPACE      # Si pones un espacio antes de un comando, NO lo guarda (ideal para contraseñas)
setopt HIST_REDUCE_BLANKS     # Limpia espacios en blanco extra en los comandos guardados
setopt HIST_VERIFY            # !! y similares se expanden primero para que los revises

# ==============================================================================
# OPCIONES EXTRA DE ZSH
# ==============================================================================
setopt AUTO_CD                # Escribe solo el nombre de una carpeta para entrar a ella (sin poner 'cd')
setopt INTERACTIVE_COMMENTS   # Permite pegar comandos de internet que tengan '#' al final sin que dé error
setopt EXTENDED_GLOB          # Patrones avanzados: ^, ~, (#i)...
setopt NO_BEEP

# Autocompletado: menú navegable, sin distinguir mayúsculas, con colores y caché
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/completion"

# fzf-tab: el menú de Tab lo dibuja fzf (mismo estilo que Ctrl+R/Ctrl+T, ver FZF_DEFAULT_OPTS).
# Pide 'menu no' y grupos sin códigos de color ([%d]); con '<' y '>' cambias de grupo.
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'
# Vista previa: carpetas en árbol al completar cd/z, contenido al completar archivos
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'lsd --tree --depth 1 --color=always $realpath'
zstyle ':fzf-tab:complete:(cat|bat|code|nano|less|cp|mv|rm):*' fzf-preview \
    '[[ -d $realpath ]] && lsd --tree --depth 1 --color=always $realpath || bat --style=numbers --color=always --line-range :200 $realpath'

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

# Actualización en Arch Linux (repos oficiales + AUR)
alias update='yay -Syu'
# Limpieza: paquetes huérfanos y caché antigua de pacman/yay
alias limpiar='pacman -Qdtq | sudo pacman -Rns - 2>/dev/null; sudo paccache -rk2; sudo paccache -ruk0; yay -Sc --aur --noconfirm'
# Repasar archivos .pacnew/.pacsave pendientes
# (con VS Code: --sudo usa sudoedit, así que code se abre como tu usuario, no como root)
alias pacnew='DIFFPROG="code --wait --diff" pacdiff --sudo'
# Mirrors más rápidos (usa /etc/xdg/reflector/reflector.conf)
alias mirrors='sudo systemctl start reflector.service && head -20 /etc/pacman.d/mirrorlist'

# ==============================================================================
# INTEGRACIONES (FZF, zoxide y scripts)
# ==============================================================================
# El código de arranque de fzf y zoxide es siempre el mismo: se guarda en caché
# y solo se regenera cuando se actualiza el programa (~13 ms menos por shell).
_cached_init() {  # _cached_init <nombre> <comando> [args…]
    local cache="$ZSH_CACHE_DIR/$1.zsh" bin=${commands[$2]}
    shift
    [[ -n $bin ]] || return 0
    [[ -s $cache && $cache -nt $bin ]] || "$@" >| "$cache"
    source "$cache"
}

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
_cached_init fzf-init fzf --zsh

# zoxide: 'z carpeta' salta a directorios frecuentes, 'zi' con buscador fzf
_cached_init zoxide-init zoxide init zsh
unfunction _cached_init

# Reemplazo de cat por bat con resaltado de sintaxis
alias cat='bat'


# ==============================================================================
# FZF + BAT: BUSCADOR BORROSO CON VISTA PREVIA
# ==============================================================================

# 1. Usar 'fd' por defecto (más rápido, ignora archivos ocultos inútiles y respeta .gitignore)
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden --exclude .git'

# 2. Aspecto común (Ctrl+R, Ctrl+T, Alt+C y el menú de Tab), con la paleta del tema 1mitema:
#    ventana con marco, buscador arriba, la línea actual resaltada entera y lo que coincide en lavanda.
export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --info=inline-right \
--highlight-line --cycle --prompt='❯ ' --pointer='▶' --gutter=' ' --marker='✓' --scrollbar='│' --separator='─' \
--color=fg:#cdd6f4,fg+:#ffffff,bg+:#3b3e4f,hl:#a797e1,hl+:#cdb6e7,query:#ffffff \
--color=info:#6d98cc,prompt:#a797e1,pointer:#cdb6e7,marker:#95d58f,spinner:#a797e1 \
--color=header:#6d98cc,border:#6a82c3,separator:#3b3e4f,scrollbar:#6a82c3,gutter:-1"

# 3. Cada buscador con su línea de ayuda; vista previa con 'bat' (archivos) y 'lsd' (carpetas)
#    Ctrl+R: un comando por fila (los pegados de varias líneas ya no ocupan media pantalla);
#    con ? se ve entero abajo.
export FZF_CTRL_R_OPTS="--no-multi-line --no-wrap \
--header='Enter: pegar  ·  ?: ver entero  ·  Ctrl+Y: copiar  ·  Esc: salir' \
--preview='echo {2..}' --preview-window='down,5,wrap,border-top,hidden' --bind='?:toggle-preview' \
--bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --color=never --hidden --exclude .git'
export FZF_CTRL_T_OPTS="--header='Enter: pegar ruta  ·  Tab: marcar varias  ·  Esc: salir' \
--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=right:60%"
export FZF_ALT_C_OPTS="--header='Enter: entrar en la carpeta  ·  Esc: salir' \
--preview 'lsd --tree --depth 2 --color=always {}' --preview-window=right:60%"

# 3. Asignar 'Ctrl+F' a la búsqueda de archivos
bindkey '^f' fzf-file-widget



# Ruleta Rusa de Fastfetch (glob de zsh en vez de find|shuf: sin procesos extra)
LOGO_DIR="$HOME/.config/fastfetch/logos"
logos=("$LOGO_DIR"/*(N.))
if (( $#logos )); then
    # Elige un archivo al azar de la carpeta
    fastfetch --logo "${logos[RANDOM % $#logos + 1]}" -c "$HOME/.config/fastfetch/config-compact.jsonc"
else
    # Si por lo que sea no encuentra la carpeta, carga el normal
    fastfetch -c "$HOME/.config/fastfetch/config-compact.jsonc"
fi
unset logos


alias reloj='kitty -o font_size=25 tty-clock -c -C 7 -b -d "%d/%m/%Y" & disown'

alias elec='source /opt/esp-idf/export.sh'
export FLYWIRE_V783_DIR="$HOME/fly"
