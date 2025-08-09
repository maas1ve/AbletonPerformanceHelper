#
//  make-pkg.sh
//  AbletonPerformanceHelper
//
//  Created by Lewis Edwards on 09/08/2025.
//


#!/bin/bash
set -euo pipefail

APP_VER="1.0"
ROOT="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$ROOT/Payload"
SCRIPTS="$ROOT/Scripts"
OUT="$ROOT/out"
mkdir -p "$OUT"

HELPER="$PAYLOAD/PrivilegedHelperTools/com.maas1ve.AbletonPerformanceHelper.helper"
if [ ! -x "$HELPER" ]; then
  echo "❌ Missing helper binary at: $HELPER"
  echo "Build helper (Release) and copy it there."
  exit 1
fi

pkgbuild --root "$PAYLOAD" \
  --scripts "$SCRIPTS" \
  --identifier com.maas1ve.APH.Core \
  --version "$APP_VER" \
  --install-location / \
  "$OUT/core.pkg"

productbuild \
  --distribution "$ROOT/Distribution.xml" \
  --package-path "$OUT" \
  "$OUT/AbletonPerformanceHelper-Installer.pkg"

echo "✅ Built: $OUT/AbletonPerformanceHelper-Installer.pkg"
