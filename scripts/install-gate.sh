#!/usr/bin/env bash
# Run ON THE SERVER (as root) to set up the passcode gate in front of the app.
#   - one passcode box, remembered for 400 days (renewed on every visit)
#   - 10 guesses per minute per visitor
#   - only the app is reachable through it
# Usage: sudo ./install-gate.sh <domain> "<passcode>"
#   e.g. sudo ./install-gate.sh example.com "my secret phrase"
set -euo pipefail
domain="${1:?usage: install-gate.sh <domain> <passcode>}"
passcode="${2:?usage: install-gate.sh <domain> <passcode>}"
here="$(cd "$(dirname "$0")/.." && pwd)"
G=/DATA/AppData/waink-gate

# Passcode match: any capitals, any spacing between words
regex='~*^\s*'
first=1
for word in $passcode; do
  w=$(printf '%s' "$word" | sed -e 's/[][\.*^$+?(){}|/]/\\&/g')
  if [ $first = 1 ]; then regex="$regex$w"; first=0; else regex="$regex\\s*$w"; fi
done
regex="$regex\\s*\$"

token=$(openssl rand -hex 32)
mkdir -p "$G/conf.d" "$G/gate"
sed -e "s|__PASSCODE_REGEX__|$(printf '%s' "$regex" | sed -e 's/[\/&|]/\\&/g')|" \
    -e "s|__AUTH_TOKEN__|$token|g" \
    -e "s|__DOMAIN__|$domain|g" \
    "$here/gate/default.conf.template" > "$G/conf.d/default.conf"
chmod 600 "$G/conf.d/default.conf"
cp "$here/gate/__gate.html" "$G/gate/__gate.html"

docker rm -f waink-gate >/dev/null 2>&1 || true
docker run -d --name waink-gate --restart unless-stopped --network host \
  -v "$G/conf.d:/etc/nginx/conf.d:ro" \
  -v "$G/gate:/etc/nginx/gate:ro" nginx:alpine >/dev/null
sleep 2
docker exec waink-gate nginx -t
echo "Gate running on 127.0.0.1:30607 for $domain"
