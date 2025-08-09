#!/bin/zsh
set -euo pipefail
log() { echo "[$(date +'%F %T')] $*"; }

STATE_DIR="$HOME/Library/Application Support/AbletonPerformanceHelper"
STOPPED_AGENTS="$STATE_DIR/agents.stopped"

log "Re-enabling Time Machine auto-backups (best-effort)…"
if command -v tmutil >/dev/null 2>&1; then
  tmutil enable || true
fi

log "Resuming Spotlight indexing (best-effort)…"
if command -v mdutil >/dev/null 2>&1; then
  for vol in /System/Volumes/Data /; do
    mdutil -i on "$vol" || true
  done
fi

log "Restoring per-user LaunchAgents we stopped…"
if [[ -f "$STOPPED_AGENTS" ]]; then
  sort -u "$STOPPED_AGENTS" | while read -r label; do
    if [[ -f "$HOME/Library/LaunchAgents/$label.plist" ]]; then
      launchctl bootstrap "gui/$UID" "$HOME/Library/LaunchAgents/$label.plist" 2>/dev/null || true
    fi
    launchctl enable "gui/$UID/$label" 2>/dev/null || true
  done
  rm -f "$STOPPED_AGENTS"
fi

log "Performance mode disabled."
