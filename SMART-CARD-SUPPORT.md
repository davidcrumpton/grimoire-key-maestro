# GKM Smart Card Support

A complete, configurable smart card checking system for GKM!

## 📦 New Files

### Tools

- **`gkm-card-check`** — Smart card validator (checks if cards are inserted and usable)
- **`gkm-card-setup`** — Interactive setup helper for configuring your smart cards

### Configuration

- **`cards.yaml.example`** — Template for `~/.gkm/cards/config.yaml`
- **`CARD-CHECK-SETUP.md`** — Complete documentation and usage guide

### Updated Files

- **`install.sh`** — Now installs the card tools and creates `~/.gkm/cards/` directory
- **`README.md`** — Added section about smart card support

---

## 🚀 Quick Start

### 1. Install (if not already done)

```bash
cd ~/Workspace/grimoire-key-maestro
chmod +x install.sh
./install.sh
```

### 2. Configure Your Smart Cards

```bash
gkm-card-setup
```

This interactive tool will:

- Ask for your card name (e.g., "primary-key", "backup-key")
- Ask for your YubiKey serial number (find with: `gpg --card-status`)
- Ask for your GPG recipient email
- Create `~/.gkm/cards/config.yaml`

### 3. Use It

```bash
# Quick check
gkm-card-check

# Check specific card
gkm-card-check primary-key

# See all cards
gkm-card-check --list

# Detailed status
gkm-card-check --status
```

---

## ✨ Key Features

### ✅ Multiple Smart Cards

Define multiple YubiKeys or smart cards with different signing identities:

```yaml
primary-key:
  serial: "4146669"
  recipient: "you@example.com"

backup-key:
  serial: "5847201"
  recipient: "backup@example.com"

work-key:
  serial: "9182736"
  recipient: "work@company.com"
```

### ✅ Non-YubiKey Users

If no cards are configured, `gkm-card-check` **silently succeeds**:

- No errors for users without YubiKeys
- Can be safely used in scripts, CI/CD, etc.
- No friction for optional smart card support

### ✅ Smart Checking

The tool checks both:

1. **SSH agent** — Verifies the key is actively offered (most reliable)
2. **GPG card status** — Confirms physical card presence

### ✅ Script-Friendly

Exit codes for automation:

```bash
if gkm-card-check; then
  echo "Card ready, proceeding with signing"
else
  echo "Card not found, skipping signing"
  exit 1
fi
```

---

## 📝 Configuration Format

Create `~/.gkm/cards/config.yaml`:

```yaml
my-card-name:
  serial: "12345678"              # Required: Your YubiKey serial
  recipient: "user@example.com"   # Required: GPG recipient for signing
  description: "My primary key"   # Optional: Human-readable label
```

**Find Your Serial:**

```bash
# Easiest way
ssh-add -l | grep cardno

# Or from GPG
gpg --card-status | grep Serial
```

---

## 🛠️ Example Workflows

### Pre-flight Check in Shell Init

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Check if signing key is available
if command -v gkm-card-check &>/dev/null; then
  gkm-card-check 2>/dev/null && echo "✓ Signing ready"
fi
```

### CI/CD Integration

```yaml
# .github/workflows/sign.yml
- name: Verify signing key
  run: gkm-card-check primary-key
```

### Conditional Signing in Scripts

```bash
#!/bin/bash
if gkm-card-check backup-key; then
  echo "Backup key present, creating backup signature"
  gpg --sign --armor backup.tar.gz
else
  echo "Backup key not found, skipping backup signature"
fi
```

---

## 🔍 Troubleshooting

### **"Card not found in configuration"**

- Create `~/.gkm/cards/config.yaml` or run `gkm-card-setup`

### **"Card is NOT inserted or not usable"**

- Check: `gpg --card-status`
- Verify serial matches your config
- Try: `ssh-add -l` to see what SSH agent knows

### **"Exit code 0 but no cards configured"**

- This is intentional! Non-YubiKey users should pass by default

---

## 📚 Documentation

- **[CARD-CHECK-SETUP.md](./CARD-CHECK-SETUP.md)** — Complete setup and usage guide
- **[CARD ASSISTANT NEEDED.md](./CARD%20ASSISTANT%20NEEDED.md)** — Background on the problem
- **`gkm-card-check --help`** — Command reference
- **`gkm-card-setup --help`** — Setup tool help

---

## 🎯 Testing Your Setup

```bash
# Test that everything works
$ gkm-card-check --list
Configured Smart Cards:
  primary-key          Serial: 4146669       Recipient: you@example.com
    → Primary YubiKey

# Quick check (with card inserted)
$ gkm-card-check && echo "✓ Card present"
✓ Card present

# Remove your card and try again
$ gkm-card-check 2>&1 || echo "✗ Card missing (expected)"
✗ Missing or unusable cards: primary-key (4146669) (expected)
```

---

## 💡 Design Decisions

1. **YAML Configuration** — Human-readable, easy to edit, versionable
2. **Standalone Tool** — Works independently, integrates with GKM but not required
3. **Graceful Fallback** — Non-YubiKey users experience no friction
4. **Simple Checking** — Uses standard tools (gpg, ssh-add) with no dependencies
5. **Flexible** — Support for multiple cards and signing identities out of the box

---

## 🔐 Security

- Config stored in `~/.gkm/cards/` with `700` permissions (owner-only)
- Only stores non-secret information (serial numbers, emails)
- No key material or passphrases stored
- Compatible with GKM's existing security model

---

**Ready to go!** Run `gkm-card-setup` to add your first card, then use `gkm-card-check` to verify it's working.
