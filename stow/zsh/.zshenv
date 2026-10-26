# Rust (rustup): solo si existe, para no romper la shell en una instalación nueva
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
