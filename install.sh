#!/bin/sh
# SPDX-License-Identifier: MIT
# Grimoire Key Maestro (GKM) — installer

set -e

GKM_HOME="${GKM_HOME:-$HOME/.gkm}"
BIN_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Grimoire Key Maestro..."

# Create base structure
mkdir -p "$GKM_HOME/global/encrypted" "$GKM_HOME/global/plain"
chmod 700 "$GKM_HOME" "$GKM_HOME/global" \
          "$GKM_HOME/global/encrypted" "$GKM_HOME/global/plain"
echo "  Created $GKM_HOME/global/{encrypted,plain}"

# Install env loader
cp "$SCRIPT_DIR/env" "$GKM_HOME/env"
chmod 644 "$GKM_HOME/env"
echo "  Installed $GKM_HOME/env"

# Install gkm CLI
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/varmgr" "$BIN_DIR/gkm"
chmod 755 "$BIN_DIR/gkm"
echo "  Installed $BIN_DIR/gkm"

echo ""
echo "Next steps:"
echo ""
echo "  1. Add to your ~/.zshrc or ~/.bashrc:"
echo "       source $SCRIPT_DIR/shell_profile_snippet.sh"
echo ""
echo "  2. Set your GPG recipients in your shell profile (not in any vault):"
echo "       export PGP_RECIPIENT_LIST=\"you@example.com,backup@example.com\""
echo ""
echo "  3. Create your first project:"
echo "       gkm init mcphe"
echo ""
echo "  4. Store a secret:"
echo "       echo \"sk-ant-...\" | gkm encrypted ANTHROPIC_API_KEY -p mcphe"
echo ""
echo "  5. Load it:"
echo "       load_project        # auto-senses from project directory"
echo "       load_project mcphe  # or explicit"
