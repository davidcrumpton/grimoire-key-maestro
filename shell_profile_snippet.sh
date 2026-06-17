# ========================================
# Grimoire Key Maestro (GKM)
# Add this to your ~/.zshrc or ~/.bashrc
# ========================================

export GKM_HOME="$HOME/.gkm"

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
# unload_project: clear all loaded secrets from current project
# ----------------------------------------
unload_project() {
    if [ -z "$_LOADED_PROJECT" ]; then
        echo "gkm: No project currently loaded."
        return 0
    fi
    echo "gkm: Unloading all secrets for '$_LOADED_PROJECT'..."
    for _up_var in $_LOADED_PROJECT_VARS; do
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
