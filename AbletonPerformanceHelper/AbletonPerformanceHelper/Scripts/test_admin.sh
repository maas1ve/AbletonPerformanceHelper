//  test_admin.sh
//  AbletonPerformanceHelper
//
//  Created by Lewis Edwards on 09/08/2025.
//
#!/bin/zsh
set -euo pipefail
echo "[test_admin] whoami: $(whoami)"
echo "[test_admin] mdutil status:"
/usr/bin/mdutil -s -a || true
echo "[test_admin] pmset -g:"
/usr/bin/pmset -g || true
echo "[test_admin] done."
