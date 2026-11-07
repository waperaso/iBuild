#!/bin/sh
# Restores a backup into ibuild_restore and checks one request, its history, and its photo.
# The live database "ibuild" is not changed.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
src=${1:?usage: scripts/restore.sh <backup-dir>}
dump="$src/ibuild.dump"
[ -f "$dump" ] || { printf '%s\n' "нет дампа: $dump" >&2; exit 1; }
[ -d "$src/files" ] || { printf '%s\n' "нет файлов: $src/files" >&2; exit 1; }

compose() {
  docker compose -f "$root/docker-compose.yml" "$@"
}

compose exec -T db psql -U ibuild -d postgres -v ON_ERROR_STOP=1 <<'SQL'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'ibuild_restore' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS ibuild_restore;
CREATE DATABASE ibuild_restore;
SQL

compose exec -T db pg_restore -U ibuild -d ibuild_restore --no-owner --no-acl --exit-on-error < "$dump"

row=$(compose exec -T db psql -U ibuild -d ibuild_restore -At -F '|' -c "
SELECT fr.id::text,
       fr.status,
       to_char(fr.amount, 'FM999999999999990.00'),
       rf.storage_path,
       rf.size_bytes::text,
       (SELECT count(*) FROM audit_events ae WHERE ae.request_id = fr.id)::text
FROM funding_requests fr
JOIN request_files rf
  ON rf.request_id = fr.id AND rf.content_type LIKE 'image/%'
ORDER BY fr.updated_at DESC
LIMIT 1;
")

[ -n "$row" ] || { printf '%s\n' "в копии нет заявки с фото" >&2; exit 1; }

id=$(printf '%s' "$row" | cut -d'|' -f1)
status=$(printf '%s' "$row" | cut -d'|' -f2)
amount=$(printf '%s' "$row" | cut -d'|' -f3)
path=$(printf '%s' "$row" | cut -d'|' -f4)
size=$(printf '%s' "$row" | cut -d'|' -f5)
events=$(printf '%s' "$row" | cut -d'|' -f6)

rel=${path#/app/data/files/}
found=$(find "$src/files" -path "*/$rel" -type f | head -n 1)
[ -n "$found" ] || { printf '%s\n' "фото не найдено: $rel" >&2; exit 1; }

restored="$src/restored-files/$rel"
mkdir -p "$(dirname "$restored")"
cp "$found" "$restored"
actual=$(wc -c < "$restored" | tr -d ' ')
[ "$actual" = "$size" ] || { printf '%s\n' "размер фото $actual, в базе $size" >&2; exit 1; }
[ "$events" -ge 1 ] || { printf '%s\n' "у заявки нет истории" >&2; exit 1; }
[ -n "$status" ] && [ -n "$amount" ] || { printf '%s\n' "нет статуса или суммы" >&2; exit 1; }

live=$(compose exec -T db psql -U ibuild -d ibuild -At -c "SELECT current_database();")
[ "$live" = "ibuild" ] || { printf '%s\n' "рабочая база изменилась: $live" >&2; exit 1; }

printf 'restored %s status=%s amount=%s events=%s photo=%s bytes=%s\n' \
  "$id" "$status" "$amount" "$events" "$restored" "$actual"
