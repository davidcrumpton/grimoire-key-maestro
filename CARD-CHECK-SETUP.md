# GKM Card Check — Smart Card Configuration Guide

Smart card support for GKM lets you automatically check if your YubiKey or other smart card is inserted and usable. This is useful for:

- **Pre-flight checks** in shell startup scripts
- **CI/CD pipelines** that need signing capabilities
- **Multiple YubiKeys** with different signing identities
- **Graceful fallback** for users without YubiKeys

---

## 🔧 Setup

### 1. Create Your Card Configuration

After installing GKM, create `~/.gkm/cards/config.yaml`:

```yaml
primary-key:
  serial: "4146669"
  recipient: "you@example.com"
  description: "Primary YubiKey"

backup-key:
  serial: "5847201"
  recipient: "backup@example.com"
  description: "Backup YubiKey"
```

**Finding Your Smart Card Serial:**

```bash
# Get the serial from your card
gpg --card-status | grep "Serial number"

# Or from SSH agent (easier)
ssh-add -l | grep cardno
```

### 2. Get Your GPG Recipient

Use the email or key ID you use for signing:

```bash
# List your GPG keys
gpg --list-keys

# Or check what GKM is using
echo $PGP_RECIPIENT_LIST
```

---

## 📋 Usage

### Quick Checks

```bash
# Check all configured cards
gkm-card-check
# Returns 0 if all cards present, 1 if any missing

# Check specific card
gkm-card-check primary-key
# Returns 0 if present, 1 if missing

# List all configured cards
gkm-card-check --list

# Detailed status report
gkm-card-check --status
```

### In Scripts

Use exit codes to conditionally enable signing:

```bash
#!/bin/bash

if gkm-card-check; then
  echo "Smart card present, signing enabled"
  export GKM_SIGNING_ENABLED=true
else
  echo "Smart card not found, skipping signing"
  export GKM_SIGNING_ENABLED=false
fi
```

Or require a specific card:

```bash
# Fail if backup key is not present
if ! gkm-card-check backup-key; then
  echo "ERROR: Backup key required but not inserted"
  exit 1
fi
```

### In Shell Init (`.zshrc` / `.bashrc`)

```bash
# Check on shell startup
if command -v gkm-card-check &>/dev/null; then
  # Silent check - exit code only
  if gkm-card-check 2>/dev/null; then
    echo "✓ Smart cards ready"
  fi
fi
```

---

## 🎯 How It Works

The tool checks your smart card using two methods:

1. **SSH Agent check** — Looks if your key is actively offered (most reliable for SSH/signing)
2. **GPG card status** — Checks if the card is physically inserted

Both methods must find the card for it to be considered "usable".

---

## 💡 Multiple YubiKeys / Backup Keys

You can define multiple cards for different purposes:

```yaml
# Primary signing key
primary-key:
  serial: "4146669"
  recipient: "you@example.com"

# Backup for disaster recovery
backup-key:
  serial: "5847201"
  recipient: "backup@example.com"

# Secondary key for different email
work-key:
  serial: "9182736"
  recipient: "work@company.com"
```

Then check them individually:

```bash
gkm-card-check primary-key    # Check main key
gkm-card-check backup-key     # Check backup
gkm-card-check --status       # Show all
```

---

## 🚀 For Non-YubiKey Users

If you don't have a smart card configured, `gkm-card-check` **silently succeeds**. This means:

- Scripts using `if gkm-card-check` will work fine without errors
- No configuration needed if you're not using YubiKeys
- You can add card support later by creating the config file

```bash
# This works whether or not you have a smart card:
if gkm-card-check; then
  echo "Card ready"
fi
```

---

## 🐛 Troubleshooting

### "Card not found in configuration"

Make sure you've created `~/.gkm/cards/config.yaml` with the card defined.

### "Card is NOT inserted or not usable"

Check that:
1. Your YubiKey/smart card is **physically inserted**
2. The **serial number in config matches** your card (`gpg --card-status`)
3. Your **GPG agent can access it** (`gpg --card-status` should show details)
4. Your **SSH agent is using GPG agent** for smart card forwarding

### View Current Status

```bash
# See what agents know about your keys
gpg --card-status              # Physical card status
ssh-add -l                     # SSH agent offerings
gpg-connect-agent "KEYINFO --list" /bye   # GPG agent metadata
```

---

## 📝 Example: CI/CD Integration

In your project's CI/CD pipeline (GitHub Actions, GitLab CI, etc.), you can require specific signing keys:

```yaml
# .github/workflows/sign.yml
- name: Check for signing key
  run: |
    if ! gkm-card-check primary-key; then
      echo "ERROR: Signing key not available"
      exit 1
    fi
    echo "Proceeding with signing..."
```

---

## 🔐 Security Notes

- **Config permissions:** `~/.gkm/cards/` is created with `700` permissions (owner-only)
- **No secrets stored:** Only serial numbers and recipient emails are stored
- **SSH checks only:** The tool never decrypts anything, only checks key availability
- **Compatible with GKM:** Integrates seamlessly with GKM's encryption workflow

---

## 📚 See Also

- `gkm --help` — Main GKM tool
- `gkm-card-check --help` — Full command reference
- `gpg --card-status` — GPG card information
