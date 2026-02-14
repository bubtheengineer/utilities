#!/bin/bash

CONFIG_DIR="/etc/proxmox-scripts"
STATE_DIR="/var/tmp/disk-alerts"

# ── Uninstall ──
if [ "$1" = "--uninstall" ]; then
    echo "Removing disk monitor..."
    crontab -l 2>/dev/null | grep -v "check-disk.sh" | crontab -
    rm -f /usr/local/bin/check-disk.sh
    rm -rf "$STATE_DIR"
    rm -rf "$CONFIG_DIR"
    echo "✅ Uninstalled."
    exit 0
fi

# ── Load config ──
if [ ! -f "${CONFIG_DIR}/config.env" ]; then
    echo "❌ Config not found. Run the installer first."
    exit 1
fi
source "${CONFIG_DIR}/config.env"

mkdir -p "$STATE_DIR"

send_pushover() {
    local title="$1"
    local message="$2"
    local priority="$3"

    curl -s \
        --form-string "token=${PUSHOVER_TOKEN}" \
        --form-string "user=${PUSHOVER_USER}" \
        --form-string "title=${title}" \
        --form-string "message=${message}" \
        --form-string "priority=${priority}" \
        --form-string "sound=siren" \
        https://api.pushover.net/1/messages.json > /dev/null
}

check_and_alert() {
    local name="$1"
    local usage="$2"
    local alert_file="${STATE_DIR}/${name}"

    if [ "$usage" -ge "$DISK_WARN_THRESHOLD" ]; then
        if [ ! -f "$alert_file" ] || [ "$(find "$alert_file" -mmin +${ALERT_INTERVAL})" ]; then
            if [ "$usage" -ge "$DISK_CRIT_THRESHOLD" ]; then
                PRIORITY=1
                ICON="🔴 CRITICAL"
            else
                PRIORITY=0
                ICON="⚠️ WARNING"
            fi

            send_pushover \
                "${ICON}: ${name}" \
                "${name} is at ${usage}% disk usage." \
                "${PRIORITY}"

            touch "$alert_file"
        fi
    else
        rm -f "$alert_file"
    fi
}

# ── Monitor Proxmox Host ──
HOST_USAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')
check_and_alert "proxmox-host" "$HOST_USAGE"

# ── Monitor All Running Containers ──
for CTID in $(pct list | awk 'NR>1 && /running/ {print $1}'); do
    NAME=$(pct list | awk -v id="$CTID" '$1==id {print $3}')
    USAGE=$(pct exec "$CTID" -- df / --output=pcent | tail -1 | tr -dc '0-9')
    check_and_alert "CT-${CTID}-${NAME}" "$USAGE"
done
