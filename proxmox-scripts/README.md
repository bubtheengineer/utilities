# Proxmox Scripts

## Disk Monitor

Monitors disk usage on the Proxmox host and all running LXC
containers. Sends Pushover alerts at configurable thresholds.

### Install

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/yourusername/proxmox-scripts/main/install/disk-monitor.sh)"
```

### Uninstall

```bash
check-disk.sh --uninstall
```

### Update

Re-run the install command. It will keep your existing config.

### Manual Run

```bash
check-disk.sh
```
