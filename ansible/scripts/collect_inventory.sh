#!/bin/bash
set -euo pipefail
TS=$(date +%Y%m%d-%H%M%S)
OUTDIR="/tmp/pi-inventory-$TS"
mkdir -p "$OUTDIR"

cat /etc/os-release > "$OUTDIR/os-release.txt" || true
uname -a > "$OUTDIR/uname.txt" || true
command -v lsb_release >/dev/null 2>&1 && lsb_release -a >> "$OUTDIR/os-release.txt" || true

# package managers
if command -v dpkg >/dev/null 2>&1; then
  dpkg -l > "$OUTDIR/dpkg-list.txt" 2>/dev/null || true
elif command -v rpm >/dev/null 2>&1; then
  rpm -qa > "$OUTDIR/rpm-list.txt" 2>/dev/null || true
fi

python3 -m pip freeze > "$OUTDIR/pip-freeze.txt" 2>/dev/null || true
npm -g ls --depth=0 > "$OUTDIR/npm-global.txt" 2>/dev/null || true

systemctl list-units --type=service --state=running > "$OUTDIR/services-running.txt" 2>/dev/null || true
ls /etc/systemd/system > "$OUTDIR/systemd-system-listing.txt" 2>/dev/null || true

ip addr show > "$OUTDIR/ip-addr.txt" || true
ip route show > "$OUTDIR/ip-route.txt" || true
lsblk -f > "$OUTDIR/lsblk.txt" || true

# Filesystem and disk
df -h > "$OUTDIR/df.txt" || true

crontab -l > "$OUTDIR/crontab-user.txt" 2>/dev/null || echo "no crontab" > "$OUTDIR/crontab-user.txt"
if command -v sudo >/dev/null 2>&1; then
  sudo crontab -l > "$OUTDIR/crontab-root.txt" 2>/dev/null || echo "no root crontab or sudo unavailable" > "$OUTDIR/crontab-root.txt"
else
  echo "sudo unavailable" > "$OUTDIR/crontab-root.txt"
fi

# Common app locations (adjust if different)
[ -d /etc/homeassistant ] && tar -czf "$OUTDIR/homeassistant-config.tar.gz" -C /etc homeassistant || true
[ -f /etc/mosquitto/mosquitto.conf ] && cp /etc/mosquitto/mosquitto.conf "$OUTDIR/" || true

# Find likely config files (non-exhaustive). DO NOT copy files with 'secrets' or private keys automatically.
find /etc -maxdepth 3 -type f \( -iname "*config*" -o -iname "*.conf" -o -iname "*.yaml" -o -iname "*.yml" \) -not -iname "*key*" -not -iname "*secret*" -print > "$OUTDIR/etc-config-list.txt" || true

# Summarize disk usage for key dirs
du -sh /home/* 2>/dev/null | sort -h > "$OUTDIR/home-du.txt" || true
du -sh /var/lib/* 2>/dev/null | sort -h > "$OUTDIR/var-lib-du.txt" || true

# Package results
tar -C /tmp -czf "/tmp/pi-inventory-$TS.tar.gz" "$(basename "$OUTDIR")" || true
echo "Inventory collected: /tmp/pi-inventory-$TS.tar.gz"
echo "Inspect files in $OUTDIR before sharing; remove any secrets or private keys first."