#!/bin/sh
# What the schedule runs: one backup, then removal of the old ones.
set -eu
here=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PATH=/usr/local/bin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH
export PATH
"$here/backup.sh"
"$here/backup-prune.sh" "${BACKUP_KEEP:-14}"
