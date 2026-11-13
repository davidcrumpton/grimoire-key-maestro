# GKM Hybrid Cloud/Local Storage Guide

This guide covers the hybrid storage mode added to Grimoire Key Maestro (GKM).
It lets you keep shared secrets in a synced folder (NextCloud, Dropbox, etc.)
while keeping machine-specific configuration on each host — for example, a
MacOS laptop and an Ubuntu workstation with different home directories.

---

## Storage Modes

GKM supports three modes, selected with `GKM_STORAGE_MODE`:

| Mode | Vault location | Local config | Use case |
| :--- | :--- | :--- | :--- |
| `local` | `$GKM_HOME` (default `~/.gkm`) | — | Original single-machine behavior |
| `cloud` | `$GKM_CLOUD_HOME` | — | All secrets live in a synced folder |
| `hybrid` | `$GKM_CLOUD_HOME` | `$GKM_LOCAL_DIR` | Shared secrets + per-machine settings |

`local` is the default, so existing setups keep working unchanged.

---

## Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `GKM_STORAGE_MODE` | `local` | `local`, `cloud`, or `hybrid` |
| `GKM_HOME` | `~/.gkm` | Vault path in `local` mode (and fallback) |
| `GKM_CLOUD_HOME` | `~/.gkm` | Shared vault path in `cloud`/`hybrid` mode |
| `GKM_LOCAL_DIR` | `~/.config/gkm` | Machine-specific config in `hybrid` mode |

In `cloud` and `hybrid` modes, `GKM_HOME` is set to `GKM_CLOUD_HOME` so the
loader and CLI resolve secrets consistently.

---

## Quick Setup

Run the setup wizard on each machine:

```bash
chmod +x setup-hybrid.sh
./setup-hybrid.sh
```

Or pass explicit paths (useful when NextCloud mounts in different locations):

```bash
./setup-hybrid.sh /mnt/nextcloud/.gkm ~/.config/gkm
```

The full installer supports all modes:

```bash
./install.hybrid.sh --mode hybrid \
    --cloud "$HOME/nextcloud/.gkm" \
    --local "$HOME/.config/gkm"
```

Non-interactive install (defaults to `hybrid`):

```bash
GKM_STORAGE_MODE=hybrid ./install.hybrid.sh
```

---

## Manual Setup

On both MacOS and Ubuntu:

```bash
export GKM_STORAGE_MODE=hybrid
export GKM_CLOUD_HOME="$HOME/nextcloud/.gkm"
export GKM_LOCAL_DIR="$HOME/.config/gkm"

mkdir -p "$GKM_CLOUD_HOME/global/encrypted" "$GKM_CLOUD_HOME/global/plain"
mkdir -p "$GKM_LOCAL_DIR/system"

cp varmgr.hybrid ~/.local/bin/gkm
cp env.hybrid "$GKM_CLOUD_HOME/env"
cp shell_profile_snippet.hybrid.sh "$GKM_LOCAL_DIR/shell_profile.gkm"
chmod +x ~/.local/bin/gkm
```

Then add this to `~/.zshrc` or `~/.bashrc`:

```bash
source "$HOME/.config/gkm/shell_profile.gkm"
```

---

## Architecture

```text
Shared cloud vault ($GKM_CLOUD_HOME):
├── env                         # Loader script
├── global/
│   ├── plain/                  # Public config vars
│   └── encrypted/              # GPG-encrypted secrets
├── cards/                      # Smart card config (optional)
└── [project-name]/
    ├── plain/
    └── encrypted/

Machine-local config ($GKM_LOCAL_DIR):
├── system/
│   └── settings.conf           # Mode and paths for this machine
└── shell_profile.gkm           # Shell helpers
```

Only the shared vault needs to sync. Local config never leaves the machine.

---

## Usage

Commands are unchanged:

```bash
gkm init my-app
gkm plain DB_HOST -p my-app db.internal.example.com
echo "sk-ant-..." | gkm encrypted ANTHROPIC_API_KEY -p my-app
gkm list -p my-app
gkm projects
gkm system-status
```

Load secrets into the current shell:

```bash
source "$HOME/.config/gkm/shell_profile.gkm"
load_project -p my-app
echo "$DB_HOST"
```

`gkm system-status` prints the active mode, vault path, local config path, and
project count — useful for confirming both machines point at the same vault.

---

## Demo

`demo-sync.sh` simulates an Ubuntu and a macOS machine sharing one vault:

```bash
./demo-sync.sh
```

It creates temporary directories, writes secrets as one platform, reads them as
the other, and cleans up on exit. Pass paths to use real directories instead:

```bash
./demo-sync.sh "$HOME/nextcloud/.gkm" "$HOME/.config/gkm" "$HOME/.config/gkm-mac"
```

Set `PGP_RECIPIENT_LIST` before running to include a GPG-encrypted secret.

---

## Migrating From Local Mode

This is the tested flow for moving an existing local vault into a shared vault.

### 1. Back up on every machine

```bash
TS=$(date +%Y%m%d-%H%M%S)
cp ~/.zshrc ~/.zshrc.bak.$TS           # or ~/.bashrc
cp -a ~/.gkm ~/.gkm.backup.$TS
cp ~/.local/bin/gkm ~/.local/bin/gkm.legacy.$TS
cp "$GKM_CLOUD_HOME/env" "$GKM_CLOUD_HOME/env.legacy.$TS"
```

### 2. Pick one canonical vault

Use a visible synced folder (e.g. `~/Nextcloud/gkm`). A visible folder avoids
clients that skip dot-directories. Every machine sets its own `GKM_CLOUD_HOME`;
the absolute path may differ per OS.

### 3. Migrate one machine at a time

Do this on the machine that has the local secrets, while the other machine is
idle:

```bash
export GKM_STORAGE_MODE=hybrid
export GKM_CLOUD_HOME="$HOME/Nextcloud/gkm"
export GKM_LOCAL_DIR="$HOME/.config/gkm"

mkdir -p "$GKM_CLOUD_HOME/global/plain" "$GKM_CLOUD_HOME/global/encrypted"
rsync -a "$HOME/.gkm/global/" "$GKM_CLOUD_HOME/global/"

for project in "$HOME/.gkm"/*/; do
    name=$(basename "$project")
    case "$name" in cards|global) continue ;; esac
    rsync -a "$project" "$GKM_CLOUD_HOME/$name/"
    echo "Migrated: $name"
done
```

`rsync -a` merges instead of replacing, so projects already in the shared vault
(e.g. `go`) are left intact. Skip `cards/` because smart-card config can be
machine-specific.

### 4. Verify counts before changing your shell

```bash
for d in "$HOME/.gkm"/*/; do
    name=$(basename "$d")
    case "$name" in cards|global) continue ;; esac
    printf '%-24s local=%s cloud=%s\n' "$name" \
        "$(find "$d" -type f | wc -l)" \
        "$(find "$GKM_CLOUD_HOME/$name" -type f | wc -l)"
done
```

Counts should match, and `varmgr.hybrid projects` should list every project.

### 5. Install the hybrid build on each machine

```bash
./setup-hybrid.sh "$GKM_CLOUD_HOME" "$GKM_LOCAL_DIR"
```

Run it on one machine first and let the sync complete before running it on the
next. This avoids a conflict on the shared `env` file.

### 6. Fix shell-profile precedence

Old GKM snippets differ in an important way:

- A snippet that uses `GKM_HOME="${GKM_HOME:-$HOME/.gkm}"` lets an exported
  `GKM_HOME` win.
- A snippet that uses `export GKM_HOME="$HOME/.gkm"` always forces the local
  vault, regardless of other environment variables.

Remove or replace the old snippet, and source the hybrid profile afterward:

```bash
export GKM_STORAGE_MODE=hybrid
export GKM_CLOUD_HOME="$HOME/Nextcloud/gkm"
export GKM_LOCAL_DIR="$HOME/.config/gkm"
source "$GKM_LOCAL_DIR/shell_profile.gkm"
```

Do not leave two GKM snippets sourced; they register duplicate `cd` hooks. On
macOS the usual location is `/usr/local/etc/shell_profile_snippet.sh`; on Linux
it is often `~/bin/` or `~/etc/`.

### Field notes (verified)

- Ubuntu may already export `GKM_HOME=~/Nextcloud/gkm` in `.bashrc`, making it
  effectively "cloud" before hybrid mode is enabled. In that case only the
  hybrid variables, binaries, and profile need updating.
- macOS may be stuck in local mode because a system-wide snippet hardcodes
  `GKM_HOME="$HOME/.gkm"`. That single line is the usual reason the two
  machines see different vaults.
- Keep `~/.gkm` after migration as a fallback until both machines load secrets
  successfully.

### Resetting a machine

If a machine never held its own secrets (for example a fresh Ubuntu install),
you can rebuild its local GKM config without touching the shared vault. Remove
the old snippet lines from `.bashrc`/`.zshrc`, replace the old `gkm` binary via
`setup-hybrid.sh`, and let Nextcloud download the vault again.

**Do not delete `$GKM_CLOUD_HOME` on one machine to "start over."** Nextcloud is
usually two-way: deleting the synced folder there will delete the secrets on
every other machine. If a machine's copy is corrupt, disconnect that folder in
the sync client and let it re-download.

### Machine-specific values

Hybrid mode shares the whole vault; it does not provide per-machine secret
overrides. Put host-specific values (Linux `DISPLAY`, wallet socket paths, etc.)
in separate projects such as `go-macos`, or keep them out of the shared vault.


---

## Security Notes

- **GPG agent:** Each machine needs a working `gpg-agent` and the private keys
  required to decrypt secrets.
- **Recipients:** `PGP_RECIPIENT_LIST` must be consistent across machines so
  either host can decrypt secrets the other created.
- **Key storage:** Never store private keys in the synced vault. Keep keyrings
  in each machine's own GPG home or on a hardware token.
- **Permissions:** The installer sets `700` on vault directories and `600` on
  `settings.conf`. Some sync clients adjust permissions — re-check them if your
  cloud provider does.
- **Plain secrets:** Use `gkm plain` only for non-sensitive values; anything in
  the shared vault is only as protected as the sync account.

---

## Troubleshooting

**Sync client not running**

Finder/Explorer integrations can run even when the main desktop client is not.
Check for the main Nextcloud app process (or the tray icon), not just the
extension. If the client will not launch on one machine, seed the vault from a
machine whose client is healthy and let that client upload:

```bash
rsync -a --ignore-existing --exclude 'env*' \
    "$HOME/Nextcloud/gkm/" other-host:~/Nextcloud/gkm/
```

Do not use `--delete`; it will remove secrets from the shared vault.

**Secrets not visible after sync**

```bash
gkm system-status          # confirm both machines use the same GKM_CLOUD_HOME
ls "$GKM_CLOUD_HOME"       # verify the project and global folders exist
```

**`Could not determine project`**

Pass `-p <project>`, set `GKM_PROJECT`, or run from a directory whose name
matches a project folder in the vault.

**Decryption failures**

Confirm `gpg-agent` is running, the expected secret key is available, and
`PGP_RECIPIENT_LIST` includes a key you hold.

**macOS rejects the scripts**

The scripts are POSIX `sh` and use `shasum` when `sha256sum` is unavailable.
Run them with `sh ./script.sh` if they are not marked executable.
