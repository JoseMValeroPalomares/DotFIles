#!/usr/bin/env bash
# Compila wlogout 1.2.2 con wlogout-flechas.patch en ~/.config/wlogout/bin/wlogout
# Requisitos: git, gcc, pkg-config, gtk3, gtk-layer-shell (sin meson)
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -d wlogout-1.2.2 ]]; then
    git clone -q --depth 1 --branch 1.2.2 https://github.com/ArtsyMacaw/wlogout.git wlogout-1.2.2
fi
cd wlogout-1.2.2
git checkout -q -- main.c
git apply ../wlogout-flechas.patch
printf '#define PROJECT_VERSION "1.2.2-jose"\n' > config.h
mkdir -p ../../bin
gcc -std=c11 -O2 -Wall -Wno-unused-parameter -Wno-unused-result -Wno-missing-braces -DLAYERSHELL=1 -I. \
    main.c -o ../../bin/wlogout $(pkg-config --cflags --libs gtk+-wayland-3.0 gtk-layer-shell-0)
../../bin/wlogout --version
