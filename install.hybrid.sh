#!/bin/sh
# SPDX-License-Identifier: MIT
# ========================================
# Grimoire Key Maestro (GKM) — installer with storage mode selection
#
# Usage:
#   ./install.hybrid.sh [--mode local|cloud|hybrid]
#                       [--cloud <path>] [--local <path>]
#
# Environment:
#   GKM_STORAGE_MODE  local | cloud | hybrid (default: hybrid)
#   GKM_CLOUD_HOME    shared vault path (cloud/hybrid)
#   GKM_LOCAL_DIR     machine-local config path (hybrid)
#   GKM_HOME          vault path (local)
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GKM_STORAGE_MODE="${GKM_STORAGE_MODE:-}"
CLOUD_HOME="${GKM_CLOUD_HOME:-$HOME/nextcloud/.gkm}"
LOCAL_DIR="${GKM_LOCAL_DIR:-$HOME/.config/gkm}"
BIN_DIR="$HOME/.local/bin"

usage() {
    cat <<EOF
Usage: $0 [--mode local|cloud|hybrid] [--cloud <path>] [--local <path>]

  --mode    Storage mode (default: prompt, or hybrid when non-interactive)
  --cloud   Shared vault path for cloud/hybrid (default: ~/nextcloud/.gkm)
  --local   Machine config path for hybrid (default: ~/.config/gkm)
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            GKM_STORAGE_MODE="$2"
            shift 2
            ;;
        --cloud)
            CLOUD_HOME="$2"
            shift 2
            ;;
        --local)
            LOCAL_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "gkm: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -z "$GKM_STORAGE_MODE" ]; then
    if [ -t 0 ]; then
        printf "Storage mode [local/cloud/hybrid] (hybrid): "
        read -r GKM_STORAGE_MODE
        [ -z "$GKM_STORAGE_MODE" ] && GKM_STORAGE_MODE="hybrid"
    else
        GKM_STORAGE_MODE="hybrid"
    fi
fi

case "$GKM_STORAGE_MODE" in
    local)
        VAULT_HOME="${GKM_HOME:-$HOME/.gkm}"
        ;;
    cloud)
        VAULT_HOME="$CLOUD_HOME"
        ;;
    hybrid)
        VAULT_HOME="$CLOUD_HOME"
        ;;
    *)
        echo "gkm: invalid storage mode '$GKM_STORAGE_MODE' (use local, cloud, or hybrid)" >&2
        exit 1
        ;;
esac

echo "Installing Grimoire Key Maestro (mode: $GKM_STORAGE_MODE)..."
echo "  Vault: $VAULT_HOME"

mkdir -p "$VAULT_HOME/global/encrypted" "$VAULT_HOME/global/plain"
chmod 700 "$VAULT_HOME" "$VAULT_HOME/global" \
          "$VAULT_HOME/global/encrypted" "$VAULT_HOME/global/plain"
echo "  Created $VAULT_HOME/global/{encrypted,plain}"

cp "$SCRIPT_DIR/env.hybrid" "$VAULT_HOME/env"
chmod 644 "$VAULT_HOME/env"
echo "  Installed $VAULT_HOME/env"

mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/varmgr.hybrid" "$BIN_DIR/gkm"
chmod 755 "$BIN_DIR/gkm"
echo "  Installed $BIN_DIR/gkm"

if [ -f "$SCRIPT_DIR/gkm-card-check" ]; then
    cp "$SCRIPT_DIR/gkm-card-check" "$BIN_DIR/gkm-card-check"
    chmod 755 "$BIN_DIR/gkm-card-check"
    echo "  Installed $BIN_DIR/gkm-card-check"
fi

if [ -f "$SCRIPT_DIR/gkm-card-setup" ]; then
    cp "$SCRIPT_DIR/gkm-card-setup" "$BIN_DIR/gkm-card-setup"
    chmod 755 "$BIN_DIR/gkm-card-setup"
    echo "  Installed $BIN_DIR/gkm-card-setup"
fi

mkdir -p "$VAULT_HOME/cards"
chmod 700 "$VAULT_HOME/cards"
echo "  Created $VAULT_HOME/cards"

if [ "$GKM_STORAGE_MODE" = "hybrid" ]; then
    mkdir -p "$LOCAL_DIR/system"
    chmod 700 "$LOCAL_DIR" "$LOCAL_DIR/system"
    cp "$SCRIPT_DIR/shell_profile_snippet.hybrid.sh" "$LOCAL_DIR/shell_profile.gkm"
    chmod 644 "$LOCAL_DIR/shell_profile.gkm"
    SETTINGS_DIR="$LOCAL_DIR"
    echo "  Installed $LOCAL_DIR/shell_profile.gkm"
else
    cp "$SCRIPT_DIR/shell_profile_snippet.hybrid.sh" "$VAULT_HOME/shell_profile.gkm"
    chmod 644 "$VAULT_HOME/shell_profile.gkm"
    SETTINGS_DIR="$VAULT_HOME"
    echo "  Installed $VAULT_HOME/shell_profile.gkm"
fi

{
    printf 'GKM_STORAGE_MODE="%s"\n' "$GKM_STORAGE_MODE"
    printf 'GKM_CLOUD_HOME="%s"\n' "$CLOUD_HOME"
    printf 'GKM_LOCAL_DIR="%s"\n' "$LOCAL_DIR"
} > "$SETTINGS_DIR/settings.conf"
chmod 600 "$SETTINGS_DIR/settings.conf"
echo "  Wrote $SETTINGS_DIR/settings.conf"

echo ""
echo "Next steps:"
echo ""
echo "  1. Add to your ~/.zshrc or ~/.bashrc:"
if [ "$GKM_STORAGE_MODE" = "hybrid" ]; then
    echo "       source $LOCAL_DIR/shell_profile.gkm"
else
    echo "       source $VAULT_HOME/shell_profile.gkm"
fi
echo ""
echo "  2. Set your GPG recipients (same list on every machine):"
echo "       export PGP_RECIPIENT_LIST=\"you@example.com,backup@example.com\""
echo ""
echo "  3. Create your first project:"
echo "       gkm init mcphe"
echo ""
echo "  4. Store and load a secret:"
echo "       echo \"sk-ant-...\" | gkm encrypted ANTHROPIC_API_KEY -p mcphe"
echo "       load_project -p mcphe"
echo ""
echo "  5. Check storage status:"
echo "       gkm system-status"
