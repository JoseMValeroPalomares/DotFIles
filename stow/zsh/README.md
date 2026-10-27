# Zsh + Oh My Zsh

![Zsh + Oh My Zsh](../../docs/capturas/zsh.png)

Zsh con Oh My Zsh, tema propio `1mitema` y plugins: fzf-tab, autosuggestions, syntax-highlighting y you-should-use. tmux arranca solo.

## Qué incluye

- `.zshrc` (en `~/.config/zsh/.zshrc`), `.zshenv`, `.zprofile` (arranca Hyprland con uwsm en tty1) y `.tmux.conf`.
- `custom/themes/`: 6 temas propios.
- Los plugins se clonan al instalar (ver `scripts/zsh-plugins.txt`).

## Atajos

- Esc Esc: anteponer sudo
- Ctrl+R / Ctrl+T / Alt+C: búsqueda con fzf

## Instalar solo esto

```bash
./install.sh --only zsh
```

[← Volver al README principal](../../README.md)
