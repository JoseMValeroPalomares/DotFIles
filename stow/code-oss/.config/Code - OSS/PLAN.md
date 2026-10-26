# PLAN · Optimización de Code - OSS

Aprobado por el usuario el 2026-10-21.

## Entorno
- Portátil, Arch Linux, kernel zen, Hyprland (Wayland), terminal Kitty, colores con Wallust (`~/.config/wallust/wallust.toml` + `templates/`).
- CPU i7-12700H (20 hilos), 15,3 GB RAM.
- Code - OSS 1.138.0 (paquete `code`), Electron 42, galería Open VSX. Sin `code-marketplace` ni `code-features`.
- No existe `~/.config/code-flags.conf`.
- Lenguajes: Java, Python (venv), JS/TS, C/C++ (ESP32 con **Arduino CLI por terminal**), Flutter/Dart (**Android, probablemente no instalado** → opcional, al final).
- **Ya no hay sobremesa remoto** → se elimina todo lo de desarrollo remoto/SSH.

## Decisiones del usuario
- Le gusta el aspecto actual (Catppuccin Alt Mocha + iconos catppuccin-mocha, FiraCode/JetBrainsMono Nerd Font, sin minimapa/menú/scrollbars, caret suave). **Conservarlo como base.**
- **No tocar las extensiones de Catppuccin.** El usuario cree que son dos (tema + iconos), pero hay tres instaladas: `alexdauenhauer.catppuccin-noctis`, `catppuccin.catppuccin-vsc`, `catppuccin.catppuccin-vsc-icons`. Solo informar de cuál aporta "Catppuccin Alt Mocha"; no desactivar ninguna salvo que él lo pida.
- **Quitar `jeanp413.open-remote-ssh`** (confirmado): desactivar primero, desinstalar al cerrar la fase 2.
- No nota problemas concretos; objetivo = mejorar lo que apenas ha configurado.

## Fases

### Fase 0 · Copia de seguridad y control de cambios
- El usuario ejecuta (fuera de la carpeta → lo hace él):
  ```bash
  ts=$(date +%F-%H%M); dest=~/backups/code-oss/$ts; mkdir -p "$dest"
  tar -czf "$dest/User.tar.gz" -C "$HOME/.config/Code - OSS" User
  tar -czf "$dest/extensions.tar.gz" -C "$HOME/.vscode-oss" extensions
  code --list-extensions --show-versions > "$dest/extensions.txt"
  [ -f ~/.config/code-flags.conf ] && cp ~/.config/code-flags.conf "$dest/"
  ls -lh "$dest"
  ```
- Repo git **local** (nunca con remoto) en la raíz de esta carpeta, con `.gitignore` en modo lista blanca: ignorar todo salvo `CLAUDE.md`, `PLAN.md`, `PROGRESS.md`, `.gitignore`, `User/settings.json`, `User/keybindings.json`, `User/tasks.json`, `User/snippets/`, `User/profiles/*/settings.json|keybindings.json|tasks.json|snippets/` y `argv.json`. Nunca versionar `globalStorage`, `workspaceStorage`, `History`, `logs`, `Cache*`.
- Primer commit = estado actual.

### Fase 1 · Diagnóstico y línea base
- Proyecto de referencia: `Metaheuristica` (Java, 22 archivos) y, si existe, un sketch de ESP32.
- *Developer: Startup Performance*: 3 arranques en frío y 3 en caliente, con y sin `--disable-extensions`.
- *Developer: Show Running Extensions*: tiempos de activación y activaciones `*`.
- RAM: `code --status` muestra la memoria **mal** (cifras imposibles) → usar *Developer: Open Process Explorer* y `ps -o pid,rss,args -C code-oss,electron` o `smem -tk -P electron`.
- Investigar el proceso **`agent-host`** (+ `electron-nodejs index.js`): es la parte de chat/agentes. Valorar `chat.disableAIFeatures: true`, si el usuario no usa el chat integrado (ya tiene `chat.agent.enabled: false`).
- Logs: leer `logs/<última fecha>/` y un arranque con `code --verbose 2>&1 | tee` en el scratchpad.
- Wayland: `hyprctl clients` falló por un socket obsoleto (`HYPRLAND_INSTANCE_SIGNATURE` antiguo en esa shell). Usar `hyprctl -i 0 clients` o `ls /run/user/1000/hypr/` y exportar la firma correcta; mirar `xwayland:` en la ventana de Code.
- La GPU ya está bien: `gpu_compositing`, `rasterization` y `opengl` habilitados.
- Volcar todo en la tabla de `PROGRESS.md`.

### Fase 2 · Limpieza de extensiones (desactivar antes de desinstalar)
- `jeanp413.open-remote-ssh` → desactivar y, al final de la fase, desinstalar (confirmado).
- `formulahendry.code-runner` → se sustituye por tareas en la fase 5; desactivar entonces (preguntar antes de desinstalar).
- `ms-vscode.cmake-tools` → no hace falta con Arduino CLI; preguntar al usuario si usa CMake. Si no lo usa, desactivarla o dejarla solo en el perfil C/C++.
- `mathematic.vscode-pdf` → mantener (hay PDFs en sus proyectos); quizá solo en el perfil base.
- Catppuccin → no tocar.

### Fase 3 · Rendimiento (un ajuste cada vez)
- `files.watcherExclude` / `search.exclude` / `files.exclude`: `node_modules`, `build`, `.venv`, `__pycache__`, `target`, `.gradle`, `.dart_tool`, carpetas de build de arduino-cli.
- Telemetría y red: `telemetry.telemetryLevel: "off"`, `workbench.enableExperiments: false`, `extensions.autoUpdate` solo notificar, `npm.fetchOnlinePackageInfo: false`, `git.autofetch` moderado.
- Chat/IA: `chat.disableAIFeatures` (ver fase 1).
- Funciones costosas candidatas, probando de una en una: `workbench.editor.limit`, `editor.experimental.asyncTokenization`; mantener el caret suave salvo que se note lag.
- Servidores de lenguaje (se aplica al añadirlos en la fase 5):
  - Java: `java.jdt.ls.vmargs` con `-Xmx` acotado, `java.server.launchMode: Hybrid`.
  - Python: basedpyright con `diagnosticMode: openFilesOnly` (Pylance no está en Open VSX).
  - clangd: `--background-index`, `-j=4`, `--pch-storage=memory`.
  - Dart: `onlyAnalyzeProjectsWithOpenFiles`.
- `CachedData` (77 MB): proponer qué carpetas son de versiones antiguas. **Borrar solo con permiso.**

### Fase 4 · Wayland/GPU
- Primero verificar si ya es Wayland nativo (Electron 42 debería usar ozone auto).
- Si hace falta, `code-flags.conf` mínimo: `--ozone-platform=wayland`, `--enable-wayland-ime` + `--wayland-text-input-version=3` (solo si usa IME), y `--password-store=gnome-libsecret` (comprobar que el llavero funciona).
- Probar portapapeles (wl-clipboard), arrastre de pestañas/ventana, nitidez con la escala de `hyprctl monitors`.
- `WaylandWindowDecorations` no es necesario (`titleBarStyle: custom`).
- El archivo está fuera de la carpeta → darle el contenido al usuario o pedir confirmación.

### Fase 5 · Productividad por lenguaje
- ~~Perfiles por lenguaje + `.vscode/` por proyecto~~ → **Cambio 2026-10-22 (decisión del usuario): cero configuración por proyecto.** Un único perfil con todas las extensiones de lenguaje (se activan solo con `onLanguage`, coste ~0 si no se abre ese lenguaje). Todo global: `User/settings.json`, `User/tasks.json` (con `${file}`/`${workspaceFolder}`), `User/keybindings.json`. Nada de `launch.json` ni `.vscode/` por proyecto: usar la autodetección de cada extensión.
- Extensiones (verificar Open VSX antes):
  - Java: `redhat.java`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-test`, Maven/Gradle si los usa.
  - Python: `ms-python.python`, `ms-python.debugpy`, `detachhead.basedpyright`, `charliermarsh.ruff`; venv con `python.defaultInterpreterPath`/`.venv`.
  - JS/TS: soporte integrado + ESLint/Prettier, o Biome.
  - C/C++/ESP32: `llvm-vs-code-extensions.vscode-clangd` (cpptools no funciona en OSS) + `vadimcn.vscode-lldb`. Con Arduino CLI, generar `compile_commands.json` con `arduino-cli compile --fqbn <fqbn> --only-compilation-database --build-path build`.
  - Flutter: `Dart-Code.dart-code`, `Dart-Code.flutter`, solo si el usuario instala el SDK.
  - Git: integrado + `mhutchie.git-graph` (más ligero que GitLens).
- `User/tasks.json` global: tareas Arduino CLI (compilar, subir, `arduino-cli monitor -p <puerto> -c baudrate=115200`, compiledb), ejecutar el archivo Python/Java actual → sustituye a code-runner.
- ~~`launch.json` por proyecto~~ → depuración con la configuración automática de cada extensión (Run/Debug de Java, «Python Debugger: Current File», Node auto-attach).
- `formatOnSave` por lenguaje con formateador explícito (ruff, prettier, clang-format/clangd, el de redhat.java, dart format).
- Atajos útiles en `keybindings.json` (tareas, terminal, cambio de perfil) y snippets donde ahorren tiempo (borrar `snippets/coffeescript.json` solo con permiso; es la plantilla vacía).
- `product.json`: no tocar. Si hiciera falta una *proposed API*, usar `enable-proposed-api` en `argv.json`. No usar el Marketplace de Microsoft (incumple sus términos).
- Desarrollo remoto/SSH: **descartado** (ya no tiene el sobremesa).

### Fase 6 · Estética (sin perder el aspecto actual)
- Recomendado: plantilla de Wallust que genere un tema local (`~/.vscode-oss/extensions/wallust-theme/`) como alternativa, con contrastes mínimos AA; Catppuccin Alt Mocha sigue por defecto y se cambia con un atajo. Alternativa: pywal `colors.json` + extensión *Wal Theme*. No escribir `settings.json` desde scripts.
- Ajustes finos opcionales: *stylistic sets* de ligaduras, `editor.lineHeight`, `editor.padding.top`, `workbench.tree.indent`, pestañas compactas.
- Sugerencias, que decide el usuario: scrollbars finas en vez de ocultas (accesibilidad); reactivar `explorer.confirmDelete` (seguridad).

### Fase 7 · Validación
- Repetir el protocolo de la fase 1 y comparar en `PROGRESS.md` (tabla antes/después).
- Checklist por perfil: compilar, depurar, formatear, Git, tareas de Arduino CLI, portapapeles, IME.
- Revertir con git cualquier cambio que no mejore.
