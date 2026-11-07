#!/bin/sh
# Keeps the newest backups and removes the rest. Only folders named like
# 20261028-030000 are touched, so nothing else in backups/ can be deleted.
# Usage: scripts/backup-prune.sh [how-many-to-keep]   (default 14)
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
keep=${1:-14}
case "$keep" in
  ''|*[!0-9]*) printf '%s\n' "нужно число, получено: $keep" >&2; exit 1 ;;
esac
[ "$keep" -ge 1 ] || { printf '%s\n' "хранить нужно хотя бы одну копию" >&2; exit 1; }
cd "$root/backups" 2>/dev/null || exit 0
ls -1d [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9] 2>/dev/null \
  | sort -r | tail -n +"$((keep + 1))" | while read -r old; do
    rm -rf -- "./$old"
    printf '%s\n' "удалена копия $old"
  done
