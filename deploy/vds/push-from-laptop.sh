#!/bin/sh
# Publishes the current GitHub main and this machine's Flutter web build to the VDS.
# Run from anywhere. Requires the private key, flutter, rsync, and a fast-forward on the server.
set -eu
key=${IBUILD_SSH_KEY:-$HOME/.ssh/ibuild_vds_ed25519}
host=${IBUILD_SSH_HOST:-root@46.8.195.36}
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
rsh="ssh -i $key -o IdentitiesOnly=yes"

echo "pull main on the server"
$rsh "$host" 'git -C /srv/ibuild/src pull --ff-only'

echo "build flutter web"
(cd "$root/app" && flutter build web --release --no-web-resources-cdn)

echo "upload web build and landing"
rsync -az --delete -e "$rsh" "$root/app/build/web/" "$host:/srv/ibuild/src/app/build/web/"
rsync -az --delete -e "$rsh" --exclude README.md "$root/landing/" "$host:/var/www/ibuild-landing/"
$rsh "$host" 'python3 -' << 'PY'
from pathlib import Path
page = Path("/var/www/ibuild-landing/index.html")
text = page.read_text()
needle = '<script defer src="v2-i18n.js"></script>'
tag = '<script src="/app-url.js"></script>\n'
if "/app-url.js" not in text:
    if needle not in text:
        raise SystemExit("landing: v2-i18n script tag not found")
    page.write_text(text.replace(needle, tag + needle, 1))
Path("/var/www/ibuild-landing/app-url.js").write_text(
    'window.IBUILD_APP_URL="https://admin.ibuild.uz";\n'
)
print("landing app url set")
PY

echo "rebuild api"
$rsh "$host" '/srv/ibuild/deploy.sh'
echo "check"
curl -fsS --resolve api.ibuild.uz:443:46.8.195.36 https://api.ibuild.uz/api/ready
echo
