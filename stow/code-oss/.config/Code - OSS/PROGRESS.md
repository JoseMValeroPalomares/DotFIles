# PROGRESS · Optimización de Code - OSS

## Estado
| Fase | Estado |
|---|---|
| Plan | ✅ Aprobado (2026-10-21) |
| 0 · Copia + git | ✅ 2026-10-22: copia en `~/backups/code-oss/2026-10-22-1557/` (verificada) + repo git local `main` |
| 1 · Diagnóstico | ✅ 2026-10-22 |
| 2 · Extensiones | ✅ 2026-10-22: `open-remote-ssh` desinstalada (el usuario pidió quitarla directamente) |
| 3 · Rendimiento | ✅ 2026-10-22: chat IA off, telemetría/red, exclusiones, limpieza de cachés. Los ajustes de servidores de lenguaje van con la fase 5 |
| 4 · Wayland/GPU | ✅ 2026-10-22: Wayland nativo sin flags; pruebas OK salvo arrastrar pestaña al vacío (limitación de Wayland) |
| 5 · Productividad | ✅ 2026-10-22: Java, Python, Embebido (C/C++/ESP32/CMake) y Web; todo global, sin config por proyecto |
| 6 · Estética | ✅ 2026-10-22 |
| 7 · Validación | 🟡 En curso: RAM medida; faltan Startup Performance y checklist |

## Línea base (2026-10-21)
- Extensiones (7, 62 MB):
  - `alexdauenhauer.catppuccin-noctis@3.1.9`
  - `catppuccin.catppuccin-vsc@3.19.0`
  - `catppuccin.catppuccin-vsc-icons@1.26.0`
  - `formulahendry.code-runner@0.12.2`
  - `jeanp413.open-remote-ssh@0.4.0`
  - `mathematic.vscode-pdf@0.2.6`
  - `ms-vscode.cmake-tools@1.24.42`
- `User/`: `settings.json` (2 KB), sin `keybindings.json` ni `tasks.json`, `snippets/coffeescript.json` vacío. `CachedData` 77 MB, `workspaceStorage` 5,2 MB.
- `code --status`, con el workspace Metaheuristica abierto (Java, 22 archivos):
  - Procesos: code-oss, zygote ×3, gpu-process, window, utility-network-service, **agent-host + electron-nodejs (index.js)**, extension-host, shared-process, file-watcher.
  - CPU 0 % en reposo. La columna "Mem MB" sale corrupta (valores de ~10¹⁰) → no sirve; medir con Process Explorer o `ps`.
  - GPU: gpu_compositing, rasterization, opengl, webgl y webgpu habilitados; vulkan desactivado. Bien.
  - Load avg 3, 2, 4; 7,5 GB libres de 15,3 GB.
- `hyprctl clients` falló: socket de una instancia antigua. Repetir con la firma correcta.
### Startup Performance (usuario, 2026-10-22, Metaheuristica, 1 muestra de cada)
| Métrica (ms) | Frío, con ext. | Caliente, con ext. | Frío, `--disable-extensions` | Caliente, `--disable-extensions` |
|---|---|---|---|---|
| import(workbench.desktop.main.js) | 684 | 187 | 230 | 175 |
| register extensions & spawn ext. host | 445 | 358 | 198 | 334 |
| restore & resolve visible editors | 140 | 40 | 61 | 30 |
| **workbench ready** | **1310** | **382** | **824** | **339** |
| extensions registered | 1699 | 794 | 1072 | 704 |
| Agent host didAuthenticate (desde timeOrigin) | 4188 | 1161 | — (no llegó) | 1065 |
| Memoria de la ventana (working set) | 385 MB | 543 MB | 325 MB | 606 MB |

Lectura:
- El primer arranque en frío fue de verdad en frío (sin la caché de disco del SO: import 684 ms frente a 230). El segundo «frío» ya tenía la caché caliente → **la diferencia en frío (1310 frente a 824) no es solo por las extensiones**. Comparando en caliente: 382 frente a 339 ms → **las extensiones de terceros cuestan ~40 ms**. Son baratas: icons 69+99, code-runner 8, pdf 1.
- **`GitHub.copilot-chat` es la más cara con diferencia: ~450 ms de carga + 250-320 ms de activación (~750 ms de CPU del extension host en cada arranque)**, y **`--disable-extensions` no la quita** porque es integrada. Arrastra también `vscode.microsoft-authentication` (~200 ms) y el agent host (autenticación de hasta 2 s en frío).
- Lo que pesa son las integradas de chat/IA, no tus extensiones → la mayor mejora será `chat.disableAIFeatures` (fase 3).
- Para la fase 7 hay que repetir el mismo protocolo (1 frío real tras `echo 3 > drop_caches` o tras reiniciar, y 1 caliente con Reload Window).

### Medición de Claude (2026-10-22 16:0x, Metaheuristica abierto, en reposo)
RAM real (PSS, reparte la memoria compartida; el RSS sumaba 2965 MB inflados):

| Proceso | PID | PSS |
|---|---|---|
| Extension host | 50886 | 265 MB |
| Main (`code.mjs`) | 50717 | 232 MB |
| Renderer (ventana) | 50790 | 225 MB |
| **Agent host** (chat/agentes) | 50865 | **202 MB** |
| Network service | 50766 | 180 MB |
| Shared process / file watcher (utility) | 50899 | 164 MB |
| **Copilot CLI** (`@github/copilot-linux-x64/index.js`, hijo del agent host) | 50983 | **157 MB** |
| Utility (shared process / file watcher) | 50901 | 147 MB |
| GPU | 50760 | 105 MB |
| zygotes + crashpad | — | 19 MB |
| **Total** | 13 procesos | **≈1700 MB** |

- **Chat/IA = ≈360 MB fijos (21 %)** solo con agent host + Copilot CLI, más la extensión integrada `GitHub.copilot-chat` dentro del extension host. Además **está rota**: `Cannot find module './@github/copilot/sdk'` (×10), tool sets vacíos, «not signed in», no puede crear su BD. Crea `~/.copilot/ide/*.lock`. Con `chat.agent.enabled: false` no basta → candidata clara: `chat.disableAIFeatures: true` (fase 3).
- Activación (exthost.log): con `*` solo las integradas `vscode.git`, `git-base` y `github` («Eager extensions activated» 470 ms después de arrancar el host). Con `onStartupFinished`: `GitHub.copilot-chat`, `catppuccin-vsc-icons`, **`code-runner`** y **`vscode-pdf`** (estas dos se cargan aunque no las uses). `cmake-tools` no se activa en este proyecto.
- `open-remote-ssh`: **no funciona** en esta build (no puede usar las *proposed APIs* `resolvers` y `contribViewsRemote`) → confirma que hay que quitarla.
- Otros errores inocuos de la build OSS: `source-map-support`, el túnel remoto (falta en `product.json`, es normal) y `lock() request could not be registered`.
- **Wayland: ya es nativo** (`xwayland: False`) **sin ningún flag**; Electron 42 elige ozone=wayland solo, y el proceso GPU lleva `--ozone-platform=wayland`. → los `code-oss-flags.conf` sobran (fase 4: proponer borrarlos/archivarlos, con permiso).
- Monitores: eDP-1 y HDMI-A-1, 1920×1080 a 144 Hz, escala 1 (sin escalado fraccionario → sin problemas de nitidez).
- IME: no hay `fcitx5` en ejecución.
- **El workspace está en un disco NTFS externo** (`/run/media/jose/474DE33309C01BF8`, `ntfs3`). Algunos comandos de git tardan ~100 ms frente a 1-10 ms. El vigilante de archivos y git en NTFS van más lentos que en ext4/btrfs → tenerlo en cuenta en las exclusiones de la fase 3; no es un problema de Code.

### Fase 3 · cambio 1: `chat.disableAIFeatures: true` (commit `066b827`)
| Métrica | Antes | Después | Δ |
|---|---|---|---|
| workbench ready (caliente) | 382 ms | **276 ms** | **−106 ms (−28 %)** |
| extensions registered (caliente) | 794 ms | **617 ms** | −177 ms |
| register extensions & spawn ext. host | 358 ms | 309 ms | −49 ms |
| Procesos Electron | 13 | **11** | sin agent host ni Copilot CLI |
| PSS sin renderer (y sin el server de Markdown) | 1475 MB | **1116 MB** | **≈ −360 MB** |
| Extensiones activadas al arrancar | +copilot-chat (~750 ms), +microsoft-authentication (~200 ms) | ninguna de las dos | — |
- `main.log`: el agent host ya no arranca.
- PSS total 1670 MB, pero no se puede comparar directamente: el renderer pasó de 225 a 505 MB porque se midió después de varios *Reload Window* con el editor de Startup Performance abierto (el heap de V8 no se libera hasta el GC), y había un `.md` abierto (server de Markdown, 49 MB). Confirmar la RAM total en la fase 7 con un arranque limpio.
- Veredicto: **se mantiene**.

### Fase 3 · cambio 2: telemetría y red
`telemetry.telemetryLevel: "off"`, `workbench.enableExperiments: false`, `extensions.autoUpdate: false` + `extensions.autoCheckUpdates: true`, `npm.fetchOnlinePackageInfo: false`. `git.autofetch` se deja por defecto (off).
- Antes: 1 conexión TCP establecida de Code (151.101.193.242:443, Fastly). Efecto esperado en tiempos: nulo; gana privacidad/control. Se mantiene.

### Fase 3 · cambio 3: exclusiones
`files.watcherExclude` (12 patrones: los por defecto de `.git` + node_modules, .venv/venv, __pycache__, .pytest_cache, build, cmake-build-*, target, .gradle, .dart_tool), `search.exclude` (9) y `files.exclude` (solo __pycache__ y .pytest_cache).
- Proyectos actuales en `Uja/Tercero`: 540 archivos; solo hay carpetas de build en Gráfica (CMake+Conan: 3 `build/`, 2 `cmake-build-debug/`, <1 MB cada una). Ganancia actual pequeña; es preventivo para node_modules/.venv/builds de arduino-cli. Se mantiene.

### Fase 3 · cambio 4: limpieza de cachés (con permiso explícito del usuario)
- Borradas 3 carpetas de `CachedData` de versiones antiguas (`a44adf7…`, `08d4889…`, `3a03d6f…`; 40 MB). Se conserva `7debcd0…` (1.138, actual). `CachedData`: 78 → 39 MB.
- Borrados 2 VSIX huérfanos de `CachedExtensionVSIXs` (`jajera.vsx-remote-ssh-1.1.2`, `jeanp413.open-remote-ssh-0.5.0`; 1 MB).
- Comprobado: Code ya eliminó solo la carpeta obsoleta `open-remote-ssh-0.5.0` de `~/.vscode-oss/extensions`.
- Descartados por ahora (no hay lentitud que justificarlos): `workbench.editor.limit`, `editor.experimental.asyncTokenization`. El caret suave se mantiene.

### Fase 4 · Wayland/GPU (2026-10-22)
- Wayland nativo sin flags (`xwayland: False`); GPU con rasterización, compositing y OpenGL activos → **no hace falta `code-flags.conf`**.
- `wl-clipboard` instalado (`/usr/bin/wl-copy`, `wl-paste`).
- **Llavero**: no hay ningún proveedor de `org.freedesktop.secrets` (ni gnome-keyring, ni kwallet, ni keepassxc; solo `libsecret`). `~/.vscode-oss/argv.json` tiene `"password-store": "basic"` → los 2 secretos guardados (`vscode.github-authentication`, `vscode.microsoft-authentication`) solo están ofuscados en `globalStorage/state.vscdb`. **Decisión del usuario: dejarlo como está** (riesgo informado; alternativas: cerrar sesión de las cuentas o instalar gnome-keyring + `gnome-libsecret`).
- **Flags**: con permiso del usuario, `git rm code-oss-flags.conf` (el de esta carpeta; queda en el historial y en la copia) y quitado de la lista blanca de `.gitignore`. El de `~/.config/code-oss-flags.conf` lo borra el usuario (está fuera de la carpeta).
- El usuario borró `~/.config/code-oss-flags.conf` (verificado).
- **Pruebas del usuario**: portapapeles Code↔Kitty ✅, ventana entre los 2 monitores ✅, arrastrar archivo a la terminal integrada ✅. ❌ Arrastrar una pestaña **al vacío** no abre ventana nueva; arrastrarla **sobre Kitty** sí la abre. Causa: en Wayland una app no conoce la posición global del puntero y al soltar sobre el fondo ninguna superficie acepta el arrastre (se cancela); al soltar sobre otra ventana, sí termina y Code abre la ventana nueva. No se arregla con flags. **Alternativa**: clic derecho en la pestaña → *Move into New Window*, o el comando `workbench.action.moveEditorToNewWindow` (existe en 1.138 y no tiene atajo) → **añadir atajo en la fase 5**.
- Opcional no aplicado: `"enable-crash-reporter": true` en argv.json no envía nada en Code - OSS (no hay URL de subida), así que no hay que cambiarlo.

### Fase 5 · parte 1: base + Java (2026-10-22)
- **Cambio de plan (usuario)**: sin perfiles ni `.vscode/` por proyecto; todo global en un perfil (ver PLAN.md).
- Herramientas: OpenJDK 27 (sin Maven/Gradle), Python 3.14 + uv, Node 22, arduino-cli + core esp32 3.3.12, gcc/gdb, CMake 4.4. Faltan `clangd`, `lldb`, `ruff` (lo trae su extensión) y Flutter (omitido).
- Instaladas (Open VSX verificado, firma válida): `redhat.java@1.58.0` (linux-x64, JRE 25 embebido para jdt.ls), `vscjava.vscode-java-debug@0.60.0`, `vscjava.vscode-java-test@0.47.0`.
- `keybindings.json`: Ctrl+Alt+O mover pestaña a ventana nueva, Ctrl+Alt+T lanzar tarea, Ctrl+Alt+Shift+T repetir tarea. (Teclado US; libres de Hyprland y code-runner.)
- `tasks.json`: «Java: ejecutar archivo actual» (`java ${file}`).
- `settings.json`: `java.jdt.ls.vmargs` con `-Xmx1G`, `[java]` formatOnSave en modo `modificationsIfAvailable`.
- Metaheurística: proyecto sin build, paquetes bajo `Practica-1/src`, `Main` lee `Practica-1/config-files/config.txt` relativo a la raíz.
- **Verificado**: jdt.ls deduce sola la raíz de fuentes (proyecto invisible `Metaheuristica_33ec4a9`, `Main.java` con 0 problemas, `.class` en `workspaceStorage/…/jdt_ws/…/bin`, fuera del proyecto). Run/F5 de la extensión funciona (cwd = raíz). jdt.ls: ~860 MB PSS indexando (límite 1 GB).
- El ▶ de **code-runner** fallaba (`cd src && javac Main.java && java Main` → no encuentra `config.txt`). **El usuario desactivó code-runner** (desactivada, no desinstalada; sus 2 ajustes `code-runner.*` se quedan, son inofensivos).

### Fase 5 · parte 2: Python (2026-10-22)
- Instaladas (Open VSX, firma válida): `ms-python.python@2026.4.0` (pack: Pylance no existe en Open VSX y se omite), `ms-python.debugpy@2026.6.0`, `ms-python.vscode-python-envs@1.40.0` (del pack), `detachhead.basedpyright@1.40.2`, `charliermarsh.ruff@2026.88.0` (trae su binario de ruff).
- `settings.json`: `python.languageServer: "None"` (evita Jedi duplicado), `basedpyright.analysis.typeCheckingMode: "standard"` (el defecto `recommended` es casi estricto), `[python]` con ruff + formatOnSave en las líneas modificadas. `diagnosticMode` ya es `openFilesOnly` por defecto.
- `tasks.json`: «Python: ejecutar archivo actual» con `${command:python.interpreterPath}` (usa el .venv si existe).

- **Prueba del usuario OK** (proyecto nuevo `~/prueba-py` con `uv venv`): detecta .venv sola, imports del venv, errores de tipos, formato con ruff, tarea y F5.

### Fase 5 · parte 3: Embebido / C/C++ (2026-10-22)
- Respuestas: placa **ESP32 clásica** (`esp32:esp32:esp32`); clangd **con pacman** (`sudo pacman -S clang`, lo ejecuta el usuario).
- No hay ningún `.ino` todavía (ni en `~/Arduino` ni en `Uja`). El usuario está en `uucp` (puerto serie OK). Toolchains: `esp-x32/2601` (xtensa) y `esp-rv32/2601`.
- Instalada `llvm-vs-code-extensions.vscode-clangd@0.6.0`. **No se instala CodeLLDB**: depurar C/C++ exigiría `launch.json` por proyecto (contra el criterio cero-config) y un `launch` global en settings podría secuestrar el F5 de Java/Python. Depuración nativa: `gdb` en terminal.
- `settings.json`: `clangd.arguments` (`--background-index -j=4 --pch-storage=memory --header-insertion=never --query-driver=` gcc del sistema + toolchains ESP32), `[c]`/`[cpp]` con clangd + formatOnSave en líneas modificadas, `*.ino` → cpp.
- `tasks.json` (7 tareas): «C/C++: compilar y ejecutar archivo actual» (binario en `/tmp/code-run`), «ESP32: compilar» (grupo build → Ctrl+Shift+B), «ESP32: compilar y subir», «ESP32: monitor serie (115200)», «ESP32: preparar autocompletado (clangd)». Placa: `sketch.yaml` si existe, si no `esp32:esp32:esp32`. Puerto: primer `/dev/ttyUSB*|ttyACM*`. `build/` dentro del sketch (ya excluido del vigilante).
- **Probado en el scratchpad** (sketch Blink): compile DB 1,2 s (61 entradas), compilación 4,3 s (20 % flash), subir sin placa → «No hay ninguna placa conectada» (exit 1); tarea C++ → `suma 6`.
- Las flags del core 3.x van en archivos `@…/esp32-libs/3.3.12/flags/cpp_flags` e incluyen flags solo de GCC xtensa (`-mlongcalls`, `-mdisable-hardware-atomics`, `-mfix-esp32-psram-cache-issue`, `-mfix-esp32-psram-cache-strategy=memw`, `-fno-tree-switch-conversion`, `-fstrict-volatile-bitfields`, `-freorder-blocks`) → resuelto abajo.
- **pacman**: «mirrors rotos» era en realidad la base local desfasada (pedía `clang-23.1.3-3`, el mirror tiene `-4` → 404). Solución: `sudo pacman -Syu clang` (nunca `-Sy` sin `u`). Instalado clang/llvm-libs 23.1.3-4.
- **Pruebas `clangd --check`**: clang 23 acepta el target `xtensa-esp-elf` y las flags de GCC de Espressif sin error. Problemas encontrados y resueltos:
  1. Falso error `__GLIBC_USE` (limits.h del toolchain: `#if defined __GLIBC_USE && __GLIBC_USE(...)`, GCC no evalúa la 2.ª parte y clang sí) → `Diagnostics: Suppress: [pp_expr_bad_token_lparen]`.
  2. `.ino` sin `#include <Arduino.h>` → `Serial`, `delay`… sin declarar → `If: PathMatch: .*\.ino` + `CompileFlags: Add: [-include, Arduino.h]`.
  Resultado: `.ino` sin include → 0 errores; error real → detectado; C++ nativo → 0 errores (no le afecta).
- Gráfica (CMake + Conan con `conan_provider.cmake`; conan no instalado): clangd con su `build/compile_commands.json` existente → 0 errores en `pr1a.cpp` e `igvEscena3D.cpp` (freeglut/glu del sistema).
- **Error encontrado por el usuario**: `"base": "$gcc"` → «can't be converted into a problem matcher». `$gcc` lo aporta `ms-vscode.cpptools` (no disponible en OSS). Sustituido por un matcher propio en línea en las 3 tareas (regex probada con salida real de arduino-cli y g++: error y warning con archivo/línea/columna). Commit `6404718`.
- Índice de clangd en `.cache/clangd/` del proyecto → añadido a `files.watcherExclude`, `search.exclude` y `files.exclude`.
- **Archivos creados fuera de la carpeta (con confirmación del usuario)**: `~/.config/clangd/config.yaml` (lo de arriba) y `~/.config/git/ignore` con `.cache/clangd/` (git lo lee por defecto; verificado con `git check-ignore`). Revertir: borrar ambos archivos.

### Fase 5 · parte 4: Web (2026-10-22)
- JS/TS integrado en Code. Instaladas (Open VSX, firma válida): `esbenp.prettier-vscode@12.4.0` (trae Prettier 3.7.4, funciona sin `npm install` ni config) y `dbaeumer.vscode-eslint@3.0.34` (solo actúa si el proyecto trae config de ESLint).
- ⚠️ Las dos se activan con `onStartupFinished` (siempre, tras el arranque) → medir su coste en la fase 7.
- `settings.json`: Prettier como formateador de JS/JSX/TS/TSX/HTML/CSS/SCSS/LESS/Vue con formatOnSave en las líneas modificadas; JSON/JSONC/Markdown con el integrado (no reescribir settings.json ni los .md). `js/ts.implicitProjectConfig.checkJs: true` (errores de tipos en .js sueltos).
- **Fallo de F5 en JS (usuario)**: Code lanzado desde Hyprland (padre `systemd`, entorno mínimo, sin `SHELL`) no tiene en el PATH el Node de **fnm** (`.zshrc` añade `~/.local/share/fnm/aliases/default/bin`). La terminal integrada sí (carga `.zshrc`). → `debug.javascript.defaultRuntimeExecutable: {"pwa-node": ".../fnm/aliases/default/bin/node"}` (alias que sigue a `fnm default`). Alternativa más amplia, no aplicada: PATH en `~/.config/environment.d/` para toda la sesión gráfica.
- Corrección de Claude: «`f("hola")` saldrá subrayado» era falso (`a` es `any` → TS lo acepta). `(parameter) a: any` es el hover, no un error.
- **Error 7006 «Parameter 'a' implicitly has an 'any' type» en .js (usuario)**: `js/ts.implicitProjectConfig.strict` es `true` por defecto en 1.138; con `checkJs` hacía obligatorio tipar cada parámetro. → `strict: false` (siguen `strictNullChecks` y `strictFunctionTypes`, que tienen ajuste propio con valor `true`). Solo afecta a archivos sin tsconfig/jsconfig.
- Probado el Prettier embebido sobre JS y HTML. Nota: desde esta carpeta, Prettier CLI lo ignora todo por el `.gitignore` en lista blanca (`/*`); la extensión usa `.prettierignore`, así que no le afecta.

### Fase 6 · Estética (2026-10-22)
- Wallust 3.5.2, paleta `dark16`, backend kmeans. En Kitty el usuario ya decidió usar solo acentos (`color14`/`color15`) porque la paleta es demasiado oscura para texto (color1–3 y 9–11 casi negros). Filtros disponibles en plantillas: strip, rgb, hexa, alpha, saturate, blend, complementary, contrast.
- **Decisiones del usuario**: tema Wallust **híbrido como Kitty** (fondo/texto/sintaxis fijos Catppuccin Mocha, acentos de Wallust) como alternativa; Catppuccin Alt Mocha sigue por defecto. Retoques: los 4.
- Retoques aplicados (un commit cada uno): scrollbars `auto` de 6 px (`d3f54d2`), `explorer.confirmDelete: true` (`958c6d4`), `editor.lineHeight: 1.5` + `editor.padding.top: 8` (`5f55b97`), `workbench.tree.indent: 14` + `renderIndentGuides: always`.

- **El usuario no quiere confirmación al borrar** → `git revert` de `958c6d4` (commit `86dafc7`); `explorer.confirmDelete` vuelve a `false`.
- **Tema Wallust híbrido** (2026-10-22):
  - Plantilla generada a partir de Catppuccin Alt Mocha (MIT, aviso conservado). Su único acento es lavanda `#b4befe` (57 usos en UI). Sustituciones: 39 bordes/indicadores/iconos → `{{color14}}` + la misma transparencia; 18 textos opacos → `{{color14 | blend('#cdd6f4')}}` (mezcla 50 % con el texto de Catppuccin); cursor → `{{color15}}`. Sintaxis (21 tokenColors + semánticos) intacta.
  - **AA verificado con 10 fondos al azar** de `~/Pictures/wallpapers` (wallust con `-C` de prueba, `-s -n --no-hooks`, sin tocar destinos reales): texto ≥ 5,67:1 y bordes ≥ 4,72:1 en el peor caso (sin la mezcla, el texto bajaba a 3,62 con acentos oscuros). Original: 7,03 / 9,17.
  - Lecciones: en wallust, comillas simples dentro de `{{ }}` en JSON (las dobles escapadas rompen la plantilla); `cp` es alias de `cp -i` en zsh → usar `command cp`.
  - **Con confirmación del usuario**: instalado `local.wallust-theme@1.0.0` (VSIX propio, `~/.vscode-oss/extensions/local.wallust-theme-1.0.0/`, colores del fondo actual: acento `#EEB89A`, cursor `#EED3C4`); plantilla en `~/.config/wallust/templates/colors-vscode.json`; `wallust.toml` respaldado en `wallust.toml.bak-2026-10-22` + 2 líneas (`vscode.template`/`vscode.target`). TOML validado (11 plantillas).
  - Revertir: `code --uninstall-extension local.wallust-theme`, borrar la plantilla y restaurar `wallust.toml.bak-2026-10-22`.

### Fase 7 · Validación (2026-10-22)
**RAM (PSS) — arranque limpio, Metaheurística con `Main.java` abierto, 60 s, sin recargas:**

| Proceso | Antes (fase 1) | Después | Δ |
|---|---|---|---|
| Main (`code.mjs`) | 232 | 239 | +7 |
| Renderer | 225 | 316 | +91 (editor Java con CodeLens/semántica frente a un `.rasi` en la línea base) |
| Extension host | 265 | 266 | ≈ (ahora aloja Java, ESLint, Prettier… en vez de Copilot Chat) |
| Agent host + Copilot CLI | 359 | **0** | **−359** |
| Shared process + file watcher | 311 | 365 | +54 |
| Network service | 180 | 179 | ≈ |
| GPU | 105 | 103 | ≈ |
| Zygotes + crashpad | 19 | 18 | ≈ |
| **Total Code (comparable)** | **1701 MB, 13 proc.** | **1490 MB, 10 proc.** | **−211 MB (−12 %)** |
| ptyHost (terminal abierta; no estaba en la línea base) | — | 151 | excluido |
| jdt.ls (servidor Java, nuevo; tope 1 GB) | — | 371 | coste de la función Java |

- El ahorro bruto de quitar el chat de IA (−359 MB) se reinvierte en parte en las funciones nuevas que sí se usan; con un archivo Java abierto, Code + Java ≈ 1861 MB.
- `clangd` 78670 (1 h, padre `-zsh`) no es de Code → excluido.
- Logs de la sesión: solo avisos de *proposed APIs* de ms-python (python, debugpy, python-envs) y `python.venvPath already registered` (inofensivo). Se activan siempre (`onStartupFinished`): catppuccin-icons, vscode-pdf, merge-conflict, debug-auto-launch, **eslint**, **prettier**.

## Pendientes y notas
- **Flags (hallazgo 2026-10-22)**: el lanzador `/usr/bin/code` solo lee `~/.config/code-flags.conf` (flags de Code) y `~/.config/electron42-flags.conf` → `electron-flags.conf` (flags de Electron). Ninguno existe. Hay dos `code-oss-flags.conf` (uno en `~/.config/` y otro en esta carpeta, con `--enable-gpu-rasterization --enable-zero-copy` además) que **el lanzador ignora**. Se revisa en la fase 4.
- `argv.json` está en `~/.vscode-oss/argv.json`, fuera de esta carpeta → no se versiona aquí (va en la copia `tar` de `extensions` solo si se copia aparte; añadir `cp ~/.vscode-oss/argv.json "$dest/"`).
- **Respuestas del usuario (2026-10-22)**: usa CMake *a veces* → `cmake-tools` se queda, pero solo en el perfil Embebido (fase 5); hasta entonces, sin tocar. **No usa el chat de IA** → `chat.disableAIFeatures: true` en la fase 3. **No usa IME** → sin flags de IME en la fase 4.
- **Catppuccin** (informado, sin tocar): `workbench.colorTheme: "Catppuccin Alt Mocha"` lo aporta **`alexdauenhauer.catppuccin-noctis`**; los iconos `catppuccin-mocha` vienen de **`catppuccin.catppuccin-vsc-icons`**. **`catppuccin.catppuccin-vsc`** (Mocha/Macchiato/Frappé/Latte normales) **no se usa ahora mismo**; solo sería prescindible si el usuario lo pide.
- **Actualización automática activa**: Code actualizó sola `open-remote-ssh` 0.4.0 → 0.5.0 el 2026-10-22 a las 15:59:59 → `extensions.autoUpdate` en la fase 3.
- Flutter: el SDK probablemente no está instalado → perfil opcional al final.

## Registro de cambios
- 2026-10-22 · El usuario **desinstaló code-runner** (verificado). Quitados sus ajustes `code-runner.runInTerminal` y `code-runner.saveFileBeforeRun`.
- 2026-10-22 · Borrado `User/snippets/coffeescript.json` (plantilla vacía, sin snippets) con permiso del usuario (`git rm`, recuperable del historial).
- 2026-10-22 · Fase 2: `code --uninstall-extension jeanp413.open-remote-ssh` (estaba en la 0.5.0 por la autoactualización). Sin ajustes ni globalStorage que limpiar. La carpeta `jeanp413.open-remote-ssh-0.5.0-universal` está en `.obsolete` → Code la elimina en el próximo arranque. Revertir: `code --install-extension jeanp413.open-remote-ssh@0.4.0` o restaurar desde `extensions.tar.gz`. Quedan 6 extensiones.
- 2026-10-22 · Copia de seguridad: `~/backups/code-oss/2026-10-22-1557/` → `User.tar.gz` (5,4 MB, 4583 entradas), `extensions.tar.gz` (16 MB, 7 extensiones), `argv.json`, `code-oss-flags.conf`, `extensions.txt`. Restaurar: `tar -xzf User.tar.gz -C "$HOME/.config/Code - OSS"` y `tar -xzf extensions.tar.gz -C ~/.vscode-oss` con Code cerrado.
- 2026-10-22 · Fase 0: `git init` local + `.gitignore` en lista blanca. Primer commit = estado actual (sin cambios en la configuración).
