#!/usr/bin/env bash
# Busca secretos en el repo antes de subirlo: patrones con grep + gitleaks/trufflehog si existen.
# Uso: ./scripts/check-secrets.sh      (código de salida 1 si encuentra algo)
set -euo pipefail

REPO=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
cd "$REPO"

if [[ -t 1 ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[1m' N=$'\e[0m'; else R='' G='' Y='' B='' N=''; fi
found=0

# Archivos que nunca deberían estar en el repo (por nombre)
FORBIDDEN_NAMES='(^|/)(\.ssh|\.gnupg)/|(^|/)id_(rsa|ed25519|ecdsa)(\.pub)?$|\.(pem|p12|pfx|key)$|(^|/)\.?(zsh|bash|python)_history$|(^|/)\.jarvis_history\.json$|(^|/)token$|(^|/)\.env$|(^|/)local\.env$|(^|/)\.git-credentials$|spotify/prefs|spotify/Users/|stellar/identity|pulse/cookie|Code - OSS/User/(globalStorage|workspaceStorage|History)/|(^|/)cookies?(\.sqlite)?$'

# Contenido sospechoso
PATTERNS=(
    'ghp_[A-Za-z0-9]{36}'                          # GitHub token
    'github_pat_[A-Za-z0-9_]{40,}'                 # GitHub fine-grained
    'gh[ousr]_[A-Za-z0-9]{36}'                     # Otros tokens de GitHub
    'sk-(ant-|proj-)?[A-Za-z0-9_-]{20,}'           # Anthropic / OpenAI
    'AKIA[0-9A-Z]{16}'                             # AWS
    'AIza[0-9A-Za-z_-]{35}'                        # Google API
    'xox[abprs]-[A-Za-z0-9-]{10,}'                 # Slack
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'           # Claves privadas
    'autologin\.(saved_credentials|blob)'          # Spotify
    '(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)["'\'' ]*[:=][ "'\'']*[A-Za-z0-9/+_.=-]{12,}'
)

echo "${B}==> Archivos del repo${N}"
mapfile -t files < <(git ls-files --cached --others --exclude-standard 2>/dev/null || find . -type f -not -path './.git/*' | sed 's|^\./||')
echo "  ${#files[@]} archivos"

echo "${B}==> Nombres prohibidos${N}"
if printf '%s\n' "${files[@]}" | grep -E "$FORBIDDEN_NAMES"; then
    echo "  ${R}✗ Hay archivos que no deberían subirse${N}"
    found=1
else
    echo "  ${G}✓ Ninguno${N}"
fi

echo "${B}==> Patrones de secretos${N}"
hits=0
for p in "${PATTERNS[@]}"; do
    # xargs reparte en tandas y falla si alguna no encuentra nada: se mira la salida, no el código
    out=$(printf '%s\0' "${files[@]}" | xargs -0 grep -IinE -- "$p" 2>/dev/null || true)
    if [[ -n $out ]]; then
        echo "$out" | cut -c1-200 | sed "s/^/  ${Y}!${N} /"
        hits=1
    fi
done
if ((hits)); then
    echo "  ${R}✗ Revisa las coincidencias de arriba${N}"
    found=1
else
    echo "  ${G}✓ Sin coincidencias${N}"
fi

echo "${B}==> Escáneres externos${N}"
if command -v gitleaks >/dev/null; then
    if gitleaks detect --source . --no-banner --redact; then
        echo "  ${G}✓ gitleaks sin hallazgos${N}"
    else
        found=1
    fi
elif command -v trufflehog >/dev/null; then
    if trufflehog filesystem . --no-update --fail --only-verified; then
        echo "  ${G}✓ trufflehog sin hallazgos${N}"
    else
        found=1
    fi
else
    echo "  ${Y}!${N} Ni gitleaks ni trufflehog instalados (opcional: sudo pacman -S gitleaks)"
fi

if ((found)); then
    echo "${R}${B}Posibles secretos encontrados. No subas el repo hasta revisarlo.${N}"
    exit 1
fi
echo "${G}${B}Todo limpio.${N}"
