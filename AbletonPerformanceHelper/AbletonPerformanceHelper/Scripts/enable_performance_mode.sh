#!/bin/zsh
set -euo pipefail
log() { echo "[$(date +'%F %T')] $*"; }

STRICT=${STRICT:-0}
EXTREME=${EXTREME:-0}
ADMIN=${ADMIN:-0}   # reserved for helper-aware path (called from app later)

STATE_DIR="$HOME/Library/Application Support/AbletonPerformanceHelper"
mkdir -p "$STATE_DIR"
STOPPED_AGENTS="$STATE_DIR/agents.stopped"
: > "$STOPPED_AGENTS"
ANIMS_STATE="$STATE_DIR/.anims_touched"
: > "$ANIMS_STATE"

MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
IS_MONTEREY=$([[ "$MACOS_MAJOR" == "12" ]] && echo 1 || echo 0)
IS_SEQUOIA=$([[ "$MACOS_MAJOR" == "15" ]] && echo 1 || echo 0)

log "Stopping Time Machine (best-effort)…"
if command -v tmutil >/dev/null 2>&1; then
  tmutil stopbackup || true
  tmutil disable || log "tmutil disable may need admin; skipped if it failed."
fi

log "Pausing Spotlight (best‑effort)…"
if command -v mdutil >/dev/null 2>&1; then
  for vol in /System/Volumes/Data /; do
    mdutil -i off "$vol" || log "mdutil off failed for $vol (needs admin?)"
  done
fi

log "Booting common per‑user LaunchAgents…"
AGENTS=( com.google.keystone.agent com.microsoft.update.agent com.adobe.CCXProcess com.adobe.AdobeCreativeCloud )
if [[ "$STRICT" = "1" ]]; then
  AGENTS+=( com.apple.contactsd com.apple.AddressBook.ContactsAccountsService )
fi
for label in "${AGENTS[@]}"; do
  if launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
    if launchctl bootout "gui/$UID/$label"; then echo "$label" >> "$STOPPED_AGENTS"; fi
  fi
done

log "Applying low‑latency UI defaults…"
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write -g QLPanelAnimationDuration -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.Dock autohide-delay -float 0
defaults write com.apple.dock expose-animation-duration -float 0.001
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.Accessibility ReduceMotionEnabled -int 1
defaults write com.apple.universalaccess reduceMotion -int 1
defaults write com.apple.universalaccess reduceTransparency -int 1
defaults write com.apple.dock springboard-show-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
echo "applied" > "$ANIMS_STATE"

if [[ "$EXTREME" = "1" ]]; then
  log "EXTREME: disabling user-scope telemetry/assistant/photo/shortcuts agents…"
  EXTRA_USER_AGENTS=(
    com.apple.ReportCrash
    com.apple.analyticsd
    com.apple.suggestd
    com.apple.Siri.agent
    com.apple.assistantd
    com.apple.assistant_service
    com.apple.gamed
    com.apple.photoanalysisd
    com.apple.mediaanalysisd
  )
  if [[ "$IS_MONTEREY" = "1" ]]; then
    EXTRA_USER_AGENTS+=( com.apple.shortcuts.useractivity com.apple.sharekit.agent com.apple.parsecd )
  fi
  if [[ "$IS_SEQUOIA" = "1" ]]; then
    EXTRA_USER_AGENTS+=( com.apple.ScreenTimeAgent com.apple.PrivacyIntelligence )
  fi
  for label in "${EXTRA_USER_AGENTS[@]}"; do
    if launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
      if launchctl bootout "gui/$UID/$label"; then echo "$label" >> "$STOPPED_AGENTS"; fi
    fi
  done
fi

if [[ "$ADMIN" = "1" ]]; then
  log "ADMIN tasks: will be performed by privileged helper (app will call helper)."
else
  log "Skipping admin/system tasks (helper not invoked)."
fi

log "Quitting common GUI apps…"
APPS=( com.apple.iCal com.apple.mail com.apple.Music com.google.Chrome com.microsoft.teams2 com.spotify.client com.hnc.Discord )
for bid in "${APPS[@]}"; do osascript -e "tell application id \"$bid\" to quit" >/dev/null 2>&1 || true; done

log "Performance mode enabled. STRICT=$STRICT EXTREME=$EXTREME"
