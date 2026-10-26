# Plan — zsh y plugins

Diagnóstico: 2026-10-21 · zsh 5.9.2 · oh-my-zsh (master) · fzf 0.74.5 · zoxide 0.10 · fnm 1.39

## Contexto verificado

- `~/.zshrc` → enlace a `~/.config/zsh/.zshrc`. `ZSH_CUSTOM=~/.config/zsh/custom` (tema 1mitema y plugins de terceros).
- Cada kitty lanza zsh → plugin `tmux` hace exec de tmux → otro zsh completo (ver memoria del proyecto kitty).
- Arranque medido: 77–122 ms (zsh pelado 5–8). compaudit 15 ms, fnm env ~10, fzf --zsh ~8, zoxide ~5, fastfetch ~10.
- fnm es necesario: `playwright-cli` está en su Node v22. Solo ~/freellmapi tiene .nvmrc (= 22, la de por defecto).
- Editor: VS Code (`code`); nvim no instalado.
- En el Bash de Claude: `zsh -i -c` sin tty da "can't change option: zle" (también con la config antigua; con tty real, 0).

## Decisiones del usuario (no reabrir)

- Le gusta cómo se ve: no tocar tema, colores, fastfetch ni alias salvo arreglos.
- Repo en ~/.config/zsh. Reparar y mantener oh-my-zsh (no migrar).
- fnm sí, sin `--use-on-cd`.
- Mejoras: historial con ↑/↓, Ctrl+←/→ y `cd -<Tab>`, you-should-use, fzf-tab.
- fzf Ctrl+R / Ctrl+T: cuesta distinguir entre tanto texto → hacerlo más legible y fácil de cerrar.

## Fases

- [x] 0 Repo, enlace, tema/plugins fuera de oh-my-zsh.
- [x] 1 oh-my-zsh reparado (conflicto UD eastwood) y actualizado; plugins actualizados.
- [x] 2 Rendimiento: tmux al principio, ZSH_DISABLE_COMPFIX, caché de fzf/zoxide, fnm sin --use-on-cd.
- [x] 3 Arreglos: setup3 (sintaxis Hyprland 0.56), pacnew con VS Code.
- [x] 4 Mejoras elegidas + fzf más legible.
