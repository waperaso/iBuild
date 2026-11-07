#!/bin/sh
# Installs a daily backup at 03:00 (macOS launchd). Run it once, by hand.
# Remove it later with: launchctl unload ~/Library/LaunchAgents/com.ibuild.backup.plist
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
target="$HOME/Library/LaunchAgents/com.ibuild.backup.plist"
mkdir -p "$HOME/Library/LaunchAgents" "$root/backups"
cat > "$target" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.ibuild.backup</string>
  <key>ProgramArguments</key>
  <array><string>/bin/sh</string><string>$root/scripts/backup-scheduled.sh</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>3</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$root/backups/schedule.log</string>
  <key>StandardErrorPath</key><string>$root/backups/schedule.log</string>
</dict>
</plist>
PLIST
launchctl unload "$target" 2>/dev/null || true
launchctl load "$target"
printf '%s\n' "Копия каждый день в 03:00, хранится последних ${BACKUP_KEEP:-14}. Журнал: $root/backups/schedule.log"
