#!/bin/sh
# SPDX-License-Identifier: MIT
# ========================================
# Grimoire Key Maestro (GKM) — hybrid sync demo
#
# Simulates two machines (Ubuntu + macOS) sharing one synced
# vault while keeping machine-specific config local.
#
# Usage:
#   ./demo-sync.sh [cloud_dir] [ubuntu_local_dir] [macos_local_dir]
#
# With no arguments, temporary directories are used and removed
# on exit.
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

DEMO_ROOT=""
CLEANUP=0

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    DEMO_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/gkm-demo.XXXXXX")
    CLEANUP=1
fi

CLOUD="${1:-$DEMO_ROOT/nextcloud/.gkm}"
LOCAL_UBUNTU="${2:-$DEMO_ROOT/ubuntu/.config/gkm}"
LOCAL_MACOS="${3:-$DEMO_ROOT/macos/.config/gkm}"

cleanup() {
    if [ "$CLEANUP" -eq 1 ] && [ -n "$DEMO_ROOT" ]; then
        rm -rf "$DEMO_ROOT"
    fi
}
trap cleanup 0

gkm_as() {
    _ga_local="$1"
    shift
    GKM_STORAGE_MODE=hybrid \
    GKM_CLOUD_HOME="$CLOUD" \
    GKM_LOCAL_DIR="$_ga_local" \
        sh "$SCRIPT_DIR/varmgr.hybrid" "$@"
}

load_as() {
    _la_local="$1"
    _la_project="$2"
    (
        GKM_STORAGE_MODE=hybrid
        GKM_CLOUD_HOME="$CLOUD"
        GKM_LOCAL_DIR="$_la_local"
        export GKM_STORAGE_MODE GKM_CLOUD_HOME GKM_LOCAL_DIR
        . "$SCRIPT_DIR/env.hybrid" -p "$_la_project"
        echo "  DB_HOST=$DB_HOST"
    )
}

echo "=============================================="
echo " GKM hybrid cross-platform sync demo"
echo "=============================================="
echo ""
echo "Cloud vault (shared):  $CLOUD"
echo "Ubuntu local config:   $LOCAL_UBUNTU"
echo "macOS local config:    $LOCAL_MACOS"
echo ""

mkdir -p "$CLOUD" "$LOCAL_UBUNTU/system" "$LOCAL_MACOS/system"
printf 'GKM_STORAGE_MODE="hybrid"\nGKM_CLOUD_HOME="%s"\n' "$CLOUD" \
    > "$LOCAL_UBUNTU/system/settings.conf"
printf 'GKM_STORAGE_MODE="hybrid"\nGKM_CLOUD_HOME="%s"\n' "$CLOUD" \
    > "$LOCAL_MACOS/system/settings.conf"

echo "--- 1. Ubuntu creates a project and stores plain secrets ---"
gkm_as "$LOCAL_UBUNTU" init my-app
gkm_as "$LOCAL_UBUNTU" plain DB_HOST -p my-app db.internal.example.com
gkm_as "$LOCAL_UBUNTU" plain API_KEY -p my-app def456
echo ""

if [ -n "$PGP_RECIPIENT_LIST" ] && command -v gpg >/dev/null 2>&1; then
    echo "--- 1b. Ubuntu stores an encrypted secret (GPG) ---"
    printf '%s' "sk-ant-xyz123abc" | gkm_as "$LOCAL_UBUNTU" encrypted ANTHROPIC_API_KEY -p my-app
    echo ""
else
    echo "Note: set PGP_RECIPIENT_LIST to include encrypted secrets in this demo."
    echo ""
fi

echo "--- 2. macOS reads the shared vault ---"
load_as "$LOCAL_MACOS" my-app
echo ""

echo "--- 3. macOS lists the projects it can see ---"
gkm_as "$LOCAL_MACOS" projects
echo ""

echo "--- 4. macOS adds a second project to the shared vault ---"
gkm_as "$LOCAL_MACOS" init my-app-api
gkm_as "$LOCAL_MACOS" plain DB_URL -p my-app-api postgres://shared.example/db
echo ""

echo "--- 5. Ubuntu sees the project added by macOS ---"
gkm_as "$LOCAL_UBUNTU" list -p my-app-api
echo ""

echo "--- 6. Machine-specific config stays separate ---"
echo "Ubuntu settings: $LOCAL_UBUNTU/system/settings.conf"
echo "macOS settings:  $LOCAL_MACOS/system/settings.conf"
echo ""

echo "=============================================="
echo " Demo complete: shared secrets synced, local"
echo " configs remained machine-specific."
echo "=============================================="

if [ "$CLEANUP" -eq 1 ]; then
    echo ""
    echo "Temporary demo directories will be removed on exit."
else
    echo ""
    echo "Demo files were written to the paths shown above."
fi
