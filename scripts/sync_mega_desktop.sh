#!/usr/bin/env bash
# ==============================================================================
# Script: sync_mega_desktop.sh
# Purpose: Upload compiled Windows installer (.exe) to Vladimir's Desktop in MEGA
#          (D:\MEGA\DOCS\desktop\ -> /MEGA/DOCS/desktop/)
# Usage: ./scripts/sync_mega_desktop.sh <path_to_setup_exe> [app_prefix]
# ==============================================================================
set -euo pipefail

FILE_PATH="${1:-}"
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    echo "Usage: $0 <path_to_setup_exe> [app_prefix]"
    exit 1
fi

FILE_NAME=$(basename "$FILE_PATH")
APP_PREFIX="${2:-${FILE_NAME%%_v*}}"
MEGA_DESKTOP_PATH="/MEGA/DOCS/desktop"

echo "==> Deploying $FILE_NAME to MEGA Desktop ($MEGA_DESKTOP_PATH)..."

# Upload via DE-222 (which has authenticated mega-cmd / mega-put)
if ssh -q de-222 exit; then
    scp "$FILE_PATH" "de-222:/tmp/$FILE_NAME"
    ssh de-222 "mega-put -c /tmp/$FILE_NAME '$MEGA_DESKTOP_PATH/' && rm -f /tmp/$FILE_NAME"
    
    # Prune older releases on MEGA desktop, keeping strictly 2 latest versions
    if [ -n "$APP_PREFIX" ]; then
        ssh de-222 bash -c "'
            FILES=\$(mega-ls \"$MEGA_DESKTOP_PATH\" 2>/dev/null | grep \"^${APP_PREFIX}\" | grep \"\\.exe$\" | sort -V || true)
            COUNT=\$(echo \"\$FILES\" | grep -c . || true)
            if [ \"\$COUNT\" -gt 2 ]; then
                TO_REMOVE=\$(echo \"\$FILES\" | head -n -2)
                for rm_file in \$TO_REMOVE; do
                    echo \"Purging obsolete from MEGA desktop: \$rm_file\"
                    mega-rm \"$MEGA_DESKTOP_PATH/\$rm_file\" 2>/dev/null || true
                done
            fi
        '"
    fi
    echo "✅ Successfully deployed to MEGA Desktop: $MEGA_DESKTOP_PATH/$FILE_NAME"
else
    echo "⚠️ Warning: DE-222 SSH unreachable; could not sync to MEGA Desktop."
fi
