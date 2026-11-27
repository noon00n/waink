#!/usr/bin/env bash
# Deploy the app to the server:
#   - builds dist/index.html with the Gemini key from .env filled in (dist/ is git-ignored)
#   - renames the live index.html to the next old_N (old_1, old_2, ...) so every version is kept
#   - uploads the new index.html and icons
# Usage: ./scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || { echo "Missing .env - copy .env.example to .env and fill it in"; exit 1; }
set -a; . ./.env; set +a
: "${GEMINI_API_KEY:?Set GEMINI_API_KEY in .env}"
: "${DEPLOY_HOST:?Set DEPLOY_HOST in .env}"
: "${DEPLOY_DIR:?Set DEPLOY_DIR in .env}"

mkdir -p dist
# Fill in the key (escape characters that are special to sed)
key_escaped=$(printf '%s' "$GEMINI_API_KEY" | sed -e 's/[\/&|]/\\&/g')
sed "s|__GEMINI_KEY__|${key_escaped}|" app/index.html > dist/index.html
grep -q '__GEMINI_KEY__' dist/index.html && { echo "Key was not filled in"; exit 1; }

scp dist/index.html "$DEPLOY_HOST:/tmp/.waink-index.new"
scp -r app/icons "$DEPLOY_HOST:/tmp/.waink-icons"
ssh "$DEPLOY_HOST" bash -s -- "$DEPLOY_DIR" <<'REMOTE'
set -euo pipefail
dir="$1"; cd "$dir"
# Next free old_N (case-insensitive, matches the existing Old_1, old_3, ... naming)
n=1; while ls -1 | grep -qix "old_$n"; do n=$((n+1)); done
[ -f index.html ] && mv index.html "old_$n" && echo "previous version saved as old_$n"
mv /tmp/.waink-index.new index.html && chmod 644 index.html
mkdir -p icons && cp /tmp/.waink-icons/* icons/ && chmod 644 icons/* && rm -rf /tmp/.waink-icons
echo "deployed to $dir"
REMOTE
