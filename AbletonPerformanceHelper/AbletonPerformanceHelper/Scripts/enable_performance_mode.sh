#!/bin/zsh
set -euo pipefail
log() { echo "[$(date +'%F %T')] $*"; }

# --- NEW: strict mode toggle (0 off / 1 on) ---
STRICT=${STRICT:-0}

STATE_DIR="$HOME/Library/Application Support/AbletonPerformanceHelper"
mkdir -p "$STATE_DIR"
STOPPED_AGENTS="$STATE_DIR/agents.stopped"
: > "$STOPPED_AGENTS"

log "Stopping active Time Machine backup (best-effort)…"
if command -v tmutil >/dev/null 2>&1; then
  tmutil stopbackup || true
  tmutil disable || log "tmutil disable may need admin; skipped if it failed."
fi

log "Pausing Spotlight indexing (best‑effort)…"
if command -v mdutil >/dev/null 2>&1; then
  for vol in /System/Volumes/Data /; do
    mdutil -i off "$vol" || log "mdutil off failed for $vol (needs admin?)"
  done
fi

log "Booting out noisy per‑user LaunchAgents…"
AGENTS=(
  com.google.keystone.agent
  com.microsoft.update.agent
  com.adobe.CCXProcess
  com.adobe.AdobeCreativeCloud
)

# --- NEW: extra Apple agents only when STRICT=1 ---
if [[ "$STRICT" = "1" ]]; then
  AGENTS+=(
    com.apple.contactsd
    com.apple.AddressBook.ContactsAccountsService
  )
fi

for label in "${AGENTS[@]}"; do
  if launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
    launchctl bootout "gui/$UID/$label" && echo "$label" >> "$STOPPED_AGENTS"
  fi
done

log "Politely quitting common background apps…"
APPS=(
  com.apple.iCal
  com.apple.mail
  com.apple.Music
  com.google.Chrome
  com.microsoft.teams2
  com.spotify.client
  com.hnc.Discord
)
for bid in "${APPS[@]}"; do
  osascript -e "tell application id \"$bid\" to quit" >/dev/null 2>&1 || true
done

log "Performance mode enabled. STRICT=$STRICT"
