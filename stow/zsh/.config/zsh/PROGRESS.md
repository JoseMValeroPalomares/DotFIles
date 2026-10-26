# Progreso — zsh

## 2026-10-21

- [x] F0 `~/.config/zsh` (git): `.zshrc` (copia de `~/.zshrc`, ahora enlace; original en `~/.zshrc.bak-2026-10-21`),
      `ZSH_CUSTOM=~/.config/zsh/custom`, 6 temas propios movidos desde `~/.oh-my-zsh/themes` (cmp idénticos),
      plugins zsh-autosuggestions y zsh-syntax-highlighting movidos (diff -rq idénticos; ignorados en git),
      cambio en agnoster guardado en `patches/agnoster-mod.patch`. PROMPT idéntico antes/después.
      OJO: restaurar `~/.zshrc.bak-2026-10-21` tal cual da "theme '1mitema' not found" (falta ZSH_CUSTOM).
- [x] F1 oh-my-zsh: `git reset --hard` (conflicto UD themes/eastwood + 19 temas borrados + agnoster), `pull --ff-only`:
      df34d2b (2026-06-15) → 2100c63 (2026-10-21), 190 commits. syntax-highlighting 1d85c69 → e6683f2.
      Sin errores nuevos al arrancar, PROMPT idéntico. Arranque: 62–75 ms (antes 77–122).
- [x] F2 Rendimiento (antes → ahora, medianas de 9): zsh externo 36 → 15 ms, interno 80 → 62 ms; total por kitty
      ~116 → ~77 ms.
      - tmux al principio de .zshrc (mismas exclusiones y guarda ZSH_TMUX_AUTOSTARTED que el plugin; `new-session`
        como con AUTOCONNECT=false; si tmux falla sigue como shell normal — probado). Plugin tmux solo para alias.
      - ZSH_DISABLE_COMPFIX=true (compaudit vacío).
      - `fzf --zsh` y `zoxide init` cacheados en $ZSH_CACHE_DIR/*-init.zsh; se regeneran si el binario es más nuevo.
      - fnm: Node por defecto directo al PATH (aliases/default/bin) y `fnm` carga su entorno al primer uso;
        sin --use-on-cd (ya no hay hook en cada cd ni carpeta en /run/user por shell). node/playwright-cli OK.
      Medir el zsh externo: `env -u TMUX -u ZSH_TMUX_AUTOSTARTED` (la terminal de Claude ya está en tmux y hereda
      la guarda: sin quitarla se mide la shell completa).
- [x] F3 Arreglos:
      - setup3: `hyprctl dispatch exec "[workspace 3]" …` no vale en Hyprland 0.56 (Lua). Nueva `_hypr_exec <ws> <cmd>`
        → `hyprctl eval 'hl.exec_cmd([=[cmd]=], { workspace = "ws" })'`. Probado en special:hyprtest con comillas
        simples y espacios: argumentos intactos y escritorio correcto.
      - pacnew: `DIFFPROG="code --wait --diff" pacdiff --sudo` (nvim no instalado; --sudo usa sudoedit → VS Code
        como usuario). Ahora mismo 0 .pacnew pendientes.
- [x] setup3 eliminado a petición del usuario (nunca lo usa) junto con `_hypr_exec`. `reloj` se queda.
- [x] F4 Mejoras:
      - ↑/↓ por prefijo, Ctrl+←/→ y `cd -<Tab>` YA venían de oh-my-zsh (up-line-or-beginning-search, auto_pushd):
        no se añade nada.
      - you-should-use (clon en custom/plugins): mensaje en español y lavanda del tema, posición "after",
        ignora cat/ls (reemplazos bat/lsd). Probado: «git status» → gst; «bat x» no avisa.
      - fzf-tab (antes de autosuggestions): `menu no`, grupos `[%d]`, `use-fzf-default-opts yes`, vista previa
        lsd/bat. Tab → fzf-completion encadenado a fzf-tab-complete (fzf_default_completion), así `**<Tab>` sigue.
      - fzf legible (FZF_DEFAULT_OPTS con la paleta de 1mitema): marco, buscador arriba, --highlight-line,
        puntero ▶ y gutter en blanco (por defecto fzf 0.74 pinta ▌ en todas las filas). Cabeceras de ayuda en
        Ctrl+R/Ctrl+T/Alt+C. Ctrl+R: --no-multi-line --no-wrap (los comandos pegados de varias líneas ocupaban
        media pantalla), `?` muestra el comando entero, Ctrl+Y copia con wl-copy. Comprobado renderizando en un
        tmux aislado (`tmux -L prueba -f /dev/null`).
      - Coste: ~8 ms por plugin (zsh -i -c exit ~80 ms, sigue por debajo de los ~116 de antes de la F2).
        Tiempo hasta el primer prompt con pty: igual que la config original (el suelo del método son ~280 ms).
      - Historial: contiene claves API en claro (FREELLMAPI_API_KEY, Bearer). Avisado; HIST_IGNORE_SPACE activo.
