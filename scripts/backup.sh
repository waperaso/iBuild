#!/bin/sh
# Copies the database and request files out of the running stack.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
compose_file=${IBUILD_COMPOSE_FILE:-"$root/docker-compose.yml"}
stamp=$(date +%Y%m%d-%H%M%S)
out=${1:-"$root/backups/$stamp"}
mkdir -p "$out"
chmod 700 "$out"
docker compose -f "$compose_file" exec -T db \
  pg_dump -U ibuild -d ibuild --no-owner --format=custom > "$out/ibuild.dump"
chmod 600 "$out/ibuild.dump"
docker compose -f "$compose_file" cp api:/app/data/files "$out/files"
chmod -R go-rwx "$out/files"
printf '%s\n' "$out"
