#!/bin/bash
set -e

CONFIG_DIR="/etc/proxmox-scripts"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/tmp/disk-alerts"
REPO_BASE="https://raw.githubusercontent.com/bubtheengineer/proxmox-scripts/main"

echo "══════════════════════════════════════"
echo "  Proxmox Disk Monitor Setup"
echo "══════════════════════════════════════"

# ── Check root ──
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root"
    exit 1
fi

# ── Gather config ──
echo ""
if [ -f "${CONFIG_DIR}/config.env" ]; then
    echo "Existing config found at ${CONFIG_DIR}/config.env"
    read -p "Keep existing config? (Y/n): " KEEP
    if [ "$KEEP" != "n" ]; then
        source "${CONFIG_DIR}/config.env"
    fi
fi

if [ -z "$PUSHOVER_USER" ] || [ "$PUSHOVER_USER" = "your-user-key" ]; then
    read -p "Pushover User Key: " PUSHOVER_USER
fi

if [ -z "$PUSHOVER_TOKEN" ] || [ "$PUSHOVER_TOKEN" = "your-app-token" ]; then
    read -p "Pushover App Token: " PUSHOVER_TOKEN
fi

read -p "Warning threshold % (default 80): " WARN_INPUT
DISK_WARN_THRESHOLD=${WARN_INPUT:-80}

read -p "Critical threshold % (default 95): " CRIT_INPUT
DISK_CRIT_THRESHOLD=${CRIT_INPUT:-95}

read -p "Re-alert interval in minutes (default 1440): " INTERVAL_INPUT
ALERT_INTERVAL=${INTERVAL_INPUT:-1440}

# ── Validate Pushover ──
echo ""
echo "Testing Pushover credentials..."
RESPONSE=$(curl -s \
    --form-string "token=${PUSHOVER_TOKEN}" \
    --form-string "user=${PUSHOVER_USER}" \
    --form-string "title=✅ Proxmox Disk Monitor" \
    --form-string "message=Disk monitoring installed on $(hostname)" \
    https://api.pushover.net/1/messages.json)

if echo "$RESPONSE" | grep -q '"status":1'; then
    echo "✅ Pushover working!"
else
    echo "❌ Pushover failed: $RESPONSE"
    exit 1
fi

# ── Save config ──
mkdir -p "$CONFIG_DIR" "$STATE_DIR"

cat > "${CONFIG_DIR}/config.env" <<EOF
PUSHOVER_USER="${PUSHOVER_USER}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN}"
DISK_WARN_THRESHOLD=${DISK_WARN_THRESHOLD}
DISK_CRIT_THRESHOLD=${DISK_CRIT_THRESHOLD}
ALERT_INTERVAL=${ALERT_INTERVAL}
EOF

chmod 600 "${CONFIG_DIR}/config.env"
echo "✅ Config saved to ${CONFIG_DIR}/config.env"

# ── Download monitoring script ──
curl -sL "${REPO_BASE}/scripts/check-disk.sh" -o "${INSTALL_DIR}/check-disk.sh"
chmod +x "${INSTALL_DIR}/check-disk.sh"
echo "✅ Script installed to ${INSTALL_DIR}/check-disk.sh"

# ── Set up cron ──
CRON_JOB="0 * * * * ${INSTALL_DIR}/check-disk.sh"
if crontab -l 2>/dev/null | grep -qF "check-disk.sh"; then
    echo "✅ Cron job already exists"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Cron job added (hourly)"
fi

echo ""
echo "══════════════════════════════════════"
echo "  ✅ Setup Complete"
echo "══════════════════════════════════════"
echo "  Config:  ${CONFIG_DIR}/config.env"
echo "  Script:  ${INSTALL_DIR}/check-disk.sh"
echo "  Cron:    Hourly"
echo ""
echo "  Manual run:  check-disk.sh"
echo "  Uninstall:   check-disk.sh --uninstall"
echo "══════════════════════════════════════"
