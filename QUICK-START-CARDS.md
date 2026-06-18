# GKM Smart Card Support — Quick Reference

This is a quick-start guide for the smart card checking feature in GKM.

## Installation

The tool is included in the GKM installer. After running `./install.sh`:

```bash
gkm-card-check    # Available in ~/.local/bin
gkm-card-setup    # Interactive configuration tool
```

## One-Minute Setup

```bash
# 1. Run the interactive setup
gkm-card-setup

# 2. It will ask for:
#    - Card name (e.g., "primary-key")
#    - Serial number (find with: gpg --card-status)
#    - GPG recipient email
#    - Optional description

# 3. Done! Now you can check your cards
gkm-card-check
```

## Common Commands

| Command | What it does | Exit Code |
| --------- | ------------- | ----------- |
| `gkm-card-check` | Check all cards are present | 0 if all present, 1 if any missing |
| `gkm-card-check primary-key` | Check specific card | 0 if present, 1 if missing |
| `gkm-card-check --list` | List all configured cards | 0 |
| `gkm-card-check --status` | Show detailed status report | 0 if all present, 1 otherwise |
| `gkm-card-check --help` | Show help | 0 |

## Configuration File

Location: `~/.gkm/cards/config.yaml`

Example:

```yaml
primary-key:
  serial: "4146669"
  recipient: "you@example.com"
  description: "My YubiKey"

backup-key:
  serial: "5847201"
  recipient: "backup@example.com"
  description: "Backup key"
```

## In Your Shell Init

```bash
# ~/.zshrc or ~/.bashrc

# Check on startup (silent if successful)
if command -v gkm-card-check &>/dev/null; then
  if gkm-card-check 2>/dev/null; then
    echo "✓ Signing keys ready"
  fi
fi
```

## In Scripts

```bash
#!/bin/bash

# Require a specific card
if ! gkm-card-check primary-key; then
  echo "ERROR: Primary key not available"
  exit 1
fi

# Proceed with signing
gpg --sign myfile.txt

# Or conditional flow
if gkm-card-check; then
  sign_artifacts
else
  echo "Skipping signing, card not present"
fi
```

## Finding Your Card Serial

```bash
# Easiest (if using SSH)
ssh-add -l | grep cardno

# Or from GPG
gpg --card-status | grep Serial

# Or using the setup tool
gkm-card-setup   # It will guide you
```

## Finding Your GPG Recipient

```bash
# List your keys
gpg --list-keys

# Check what GKM uses
echo $PGP_RECIPIENT_LIST
```

## Examples: Multiple Cards

Define different cards for different purposes:

```yaml
# Primary work key
work-key:
  serial: "1234567"
  recipient: "you@work.com"

# Personal key
personal-key:
  serial: "7654321"
  recipient: "you@personal.com"

# Backup for both
backup-key:
  serial: "9999999"
  recipient: "you@work.com"
```

Then:

```bash
gkm-card-check work-key        # Check work card
gkm-card-check personal-key    # Check personal card
gkm-card-check --status        # Check all
```

## Troubleshooting

### **"No cards configured yet"**

- Run `gkm-card-setup` to add a card

### **"Card is NOT inserted or not usable"**

- Make sure card is physically inserted
- Check serial number: `gpg --card-status`
- Verify GPG can see the card: `gpg --card-status`

### **"Command not found: gkm-card-check"**

- Make sure GKM was installed: `./install.sh`
- Verify it's in your PATH: `which gkm-card-check`

### **"Exit code 0 but I don't have a YubiKey"**

- This is intentional! The tool succeeds for non-YubiKey users

## For Non-YubiKey Users

The tool is **completely optional**. If you don't have a smart card:

- Don't create a config file
- The tool will silently succeed (exit code 0)
- Your scripts will work fine
- No errors or warnings

When you later add a YubiKey, just run `gkm-card-setup` and it starts working immediately.

## Full Documentation

See [CARD-CHECK-SETUP.md](./CARD-CHECK-SETUP.md) for complete documentation.

## Command Reference

```bash
gkm-card-check --help        # Show all commands
gkm-card-setup --help        # Setup tool help
gkm-card-check --version     # Show version
```

---

**Need help?** See the full [CARD-CHECK-SETUP.md](./CARD-CHECK-SETUP.md) guide.
