#!/bin/zsh
set -euo pipefail
APP_SUPPORT="$HOME/Library/Application Support/AbletonPerformanceHelper"
mkdir -p "$APP_SUPPORT"
STATE="$APP_SUPPORT/.perf_on"

enable()  { "$APP_SUPPORT/enable_performance_mode.sh";   touch "$STATE"; }
disable() { "$APP_SUPPORT/restore_normal_mode.sh";       rm -f "$STATE" || true; }

BUNDLED="$(/usr/bin/dirname "$0")"
cp -f "$BUNDLED/enable_performance_mode.sh"   "$APP_SUPPORT/enable_performance_mode.sh"
cp -f "$BUNDLED/restore_normal_mode.sh"       "$APP_SUPPORT/restore_normal_mode.sh"
chmod +x "$APP_SUPPORT/"*.sh

while true; do
  if /usr/bin/pgrep -f "Contents/MacOS/Live" >/dev/null 2>&1 || /usr/bin/pgrep -f "com.ableton.live" >/dev/null 2>&1; then
    [[ -f "$STATE" ]] || enable
  else
    [[ -f "$STATE" ]] && disable
  fi
  /bin/sleep 5
done
