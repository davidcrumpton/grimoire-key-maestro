#!/bin/sh
# SPDX-License-Identifier: MIT
# ========================================
# Grimoire Key Maestro (GKM) — hybrid setup wizard
#
# Usage:
#   ./setup-hybrid.sh [cloud_home] [local_dir]
#
# Defaults:
#   cloud_home = $GKM_CLOUD_HOME or $HOME/nextcloud/.gkm
#   local_dir  = $GKM_LOCAL_DIR  or $HOME/.config/gkm
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [cloud_home] [local_dir]"
    echo ""
    echo "  cloud_home  Shared/synced vault (default: \$GKM_CLOUD_HOME or ~/nextcloud/.gkm)"
    echo "  local_dir   Machine-specific config (default: \$GKM_LOCAL_DIR or ~/.config/gkm)"
    exit 0
fi

GKM_STORAGE_MODE="${GKM_STORAGE_MODE:-hybrid}"
CLOUD_HOME="${1:-${GKM_CLOUD_HOME:-$HOME/nextcloud/.gkm}}"
LOCAL_DIR="${2:-${GKM_LOCAL_DIR:-$HOME/.config/gkm}}"
BIN_DIR="$HOME/.local/bin"

echo "Setting up Grimoire Key Maestro in hybrid mode..."
echo "  Cloud vault:  $CLOUD_HOME"
echo "  Local config: $LOCAL_DIR"

# Shared vault structure
mkdir -p "$CLOUD_HOME/global/encrypted" "$CLOUD_HOME/global/plain" "$CLOUD_HOME/cards"
chmod 700 "$CLOUD_HOME" "$CLOUD_HOME/global" \
          "$CLOUD_HOME/global/encrypted" "$CLOUD_HOME/global/plain"
echo "  Created $CLOUD_HOME/global/{encrypted,plain}"

# Machine-local config structure
mkdir -p "$LOCAL_DIR/system"
chmod 700 "$LOCAL_DIR" "$LOCAL_DIR/system"
echo "  Created $LOCAL_DIR/system"

# Install loader and CLI
cp "$SCRIPT_DIR/env.hybrid" "$CLOUD_HOME/env"
chmod 644 "$CLOUD_HOME/env"
echo "  Installed $CLOUD_HOME/env"

mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/varmgr.hybrid" "$BIN_DIR/gkm"
chmod 755 "$BIN_DIR/gkm"
echo "  Installed $BIN_DIR/gkm"

# Install shell profile
cp "$SCRIPT_DIR/shell_profile_snippet.hybrid.sh" "$LOCAL_DIR/shell_profile.gkm"
chmod 644 "$LOCAL_DIR/shell_profile.gkm"
echo "  Installed $LOCAL_DIR/shell_profile.gkm"

# Record machine-specific settings
{
    printf 'GKM_STORAGE_MODE="%s"\n' "$GKM_STORAGE_MODE"
    printf 'GKM_CLOUD_HOME="%s"\n' "$CLOUD_HOME"
    printf 'GKM_LOCAL_DIR="%s"\n' "$LOCAL_DIR"
} > "$LOCAL_DIR/system/settings.conf"
chmod 600 "$LOCAL_DIR/system/settings.conf"
echo "  Wrote $LOCAL_DIR/system/settings.conf"

echo ""
echo "Hybrid setup complete. Next steps:"
echo ""
echo "  1. Add this line to your ~/.zshrc or ~/.bashrc:"
echo "       source $LOCAL_DIR/shell_profile.gkm"
echo ""
echo "  2. Set your GPG recipients (same list on every machine):"
echo "       export PGP_RECIPIENT_LIST=\"you@example.com,backup@example.com\""
echo ""
echo "  3. Create a project and store a secret:"
echo "       gkm init mcphe"
echo "       echo \"sk-ant-...\" | gkm encrypted ANTHROPIC_API_KEY -p mcphe"
echo ""
echo "  4. Verify storage:"
echo "       gkm system-status"
