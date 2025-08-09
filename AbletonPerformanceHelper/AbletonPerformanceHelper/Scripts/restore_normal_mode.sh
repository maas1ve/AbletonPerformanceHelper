#!/bin/zsh
set -euo pipefail
log() { echo "[$(date +'%F %T')] $*"; }

STATE_DIR="$HOME/Library/Application Support/AbletonPerformanceHelper"
STOPPED_AGENTS="$STATE_DIR/agents.stopped"
ANIMS_STATE="$STATE_DIR/.anims_touched"

log "Restoring per‑user LaunchAgents…"
if [[ -f "$STOPPED_AGENTS" ]]; then
  if command -v tac >/dev/null 2>&1; then lines=$(tac "$STOPPED_AGENTS"); else lines=$(tail -r "$STOPPED_AGENTS"); fi
  IFS=$'\n'
  for label in $lines; do
    [[ -z "$label" ]] && continue
    if [[ -f "/System/Library/LaunchAgents/${label}.plist" ]]; then
      launchctl bootstrap "gui/$UID" "/System/Library/LaunchAgents/${label}.plist" 2>/dev/null || true
    else
      launchctl enable "gui/$UID/$label" 2>/dev/null || true
    fi
  done
  IFS=$' \t\n'; : > "$STOPPED_AGENTS"
fi

if [[ -f "$ANIMS_STATE" ]]; then
  log "Reverting UI defaults…"
  defaults delete NSGlobalDomain NSAutomaticWindowAnimationsEnabled 2>/dev/null || true
  defaults delete NSGlobalDomain NSWindowResizeTime 2>/devnull || true
  defaults delete -g QLPanelAnimationDuration 2>/dev/null || true
  defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
  defaults delete com.apple.Dock autohide-delay 2>/dev/null || true
  defaults delete com.apple.dock expose-animation-duration 2>/dev/null || true
  defaults delete com.apple.dock launchanim 2>/dev/null || true
  defaults delete com.apple.finder DisableAllAnimations 2>/dev/null || true
  defaults delete com.apple.Accessibility ReduceMotionEnabled 2>/dev/null || true
  defaults delete com.apple.universalaccess reduceMotion 2>/dev/null || true
  defaults delete com.apple.universalaccess reduceTransparency 2>/dev/null || true
  defaults delete com.apple.dock springboard-show-duration 2>/dev/null || true
  defaults delete com.apple.dock springboard-hide-duration 2>/dev/null || true
  defaults delete NSGlobalDomain NSScrollAnimationEnabled 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
  rm -f "$ANIMS_STATE"
fi

log "Performance mode restored."
