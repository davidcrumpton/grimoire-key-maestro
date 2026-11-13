# ========================================
# Grimoire Key Maestro (GKM) — hybrid profile
# Add this to your ~/.zshrc or ~/.bashrc
#
# Defaults to hybrid storage: shared secrets in a synced
# folder (e.g. NextCloud) and machine-specific config locally.
# ========================================

GKM_STORAGE_MODE="${GKM_STORAGE_MODE:-hybrid}"
: "${GKM_CLOUD_HOME:=$HOME/nextcloud/.gkm}"
: "${GKM_LOCAL_DIR:=$HOME/.config/gkm}"

case "$GKM_STORAGE_MODE" in
    local)
        : "${GKM_HOME:=$HOME/.gkm}"
        ;;
    cloud|hybrid)
        GKM_HOME="$GKM_CLOUD_HOME"
        ;;
    *)
        echo "gkm: invalid GKM_STORAGE_MODE '$GKM_STORAGE_MODE' (use local, cloud, or hybrid)" >&2
        ;;
esac

export GKM_STORAGE_MODE GKM_CLOUD_HOME GKM_LOCAL_DIR GKM_HOME

# Ensure gkm is on PATH
export PATH="$HOME/.local/bin:$PATH"

# Per-shell project tracking (no file I/O, no cross-shell bleed)
_LOADED_PROJECT=""
_LOADED_PROJECT_VARS=""

# ----------------------------------------
# load_project: source secrets for a project
#
# Usage:
#   load_project             # auto-sense from current directory
#   load_project mcphe       # explicit
#   load_project -p mcphe    # explicit with flag
# ----------------------------------------
load_project() {
    . "$GKM_HOME/env" "$@"
}

# ----------------------------------------
# reload_project: reload project secrets
# ----------------------------------------
reload_project() {
    unload_project
    load_project
}

# ----------------------------------------
# unload_project: clear all loaded secrets from current project
# ----------------------------------------
unload_project() {
    if [ -z "$_LOADED_PROJECT" ]; then
        echo "gkm: No project currently loaded."
        return 0
    fi
    echo "gkm: Unloading all secrets for '$_LOADED_PROJECT'..."
    for _up_var in $(echo $_LOADED_PROJECT_VARS); do
        unset "$_up_var"
        echo "  unset $_up_var"
    done
    _LOADED_PROJECT=""
    _LOADED_PROJECT_VARS=""
    echo "gkm: Done."
}

# ----------------------------------------
# project_status: show what's loaded in this shell
# ----------------------------------------
project_status() {
    if [ -z "$_LOADED_PROJECT" ]; then
        echo "gkm: No project loaded in this shell."
        return 0
    fi
    echo "gkm: Active project: $_LOADED_PROJECT"
    echo "Loaded vars:"
    for _ps_var in $_LOADED_PROJECT_VARS; do
        printf "  %s\n" "$_ps_var"
    done
}

# ----------------------------------------
# gkm_storage_status: show storage mode and resolved paths
# ----------------------------------------
gkm_storage_status() {
    gkm system-status
}

# ----------------------------------------
# gkm_cloud_path: print the shared cloud vault location
# ----------------------------------------
gkm_cloud_path() {
    echo "$GKM_HOME"
}

# ----------------------------------------
# gkm_local_path: print the machine-local config location
# ----------------------------------------
gkm_local_path() {
    echo "$GKM_LOCAL_DIR"
}

# ----------------------------------------
# Auto-detect project when cd'ing into a known project directory.
# Prompts to load — does not auto-load silently.
# To auto-load silently, replace the echo line with: load_project -p "$_al_project"
# ----------------------------------------
_gkm_autodetect() {
    _al_dir="$PWD"
    _al_project=""
    while [ "$_al_dir" != "/" ]; do
        _al_candidate=$(basename "$_al_dir")
        if [ -d "$GKM_HOME/$_al_candidate" ] && [ "$_al_candidate" != "global" ]; then
            _al_project="$_al_candidate"
            break
        fi
        _al_dir=$(dirname "$_al_dir")
    done

    if [ -n "$_al_project" ] && [ "$_al_project" != "$_LOADED_PROJECT" ]; then
        echo "[gkm] Detected project '$_al_project' — run 'load_project' to load secrets."
    fi
}

# Hook into cd
if [ -n "$ZSH_VERSION" ]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _gkm_autodetect
elif [ -n "$BASH_VERSION" ]; then
    _gkm_orig_cd() {
        builtin cd "$@" && _gkm_autodetect
    }
    alias cd='_gkm_orig_cd'
fi
