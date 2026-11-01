#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
install -m755 "$here/check-updates.py" /opt/weaselway/libexec/check-updates
install -m644 "$here/versions.json" /opt/weaselway/versions.json
cat > /etc/systemd/user/weaselway-update-check.service <<'EOF'
[Unit]
Description=Read-only Weaselway source and kernel compatibility check
[Service]
Type=oneshot
ExecStart=/opt/weaselway/libexec/check-updates
EOF
cat > /etc/systemd/user/weaselway-update-check.timer <<'EOF'
[Unit]
Description=Check Weaselway updates while the Arch user session is running
[Timer]
OnStartupSec=15min
OnCalendar=daily
Persistent=true
RandomizedDelaySec=30min
[Install]
WantedBy=timers.target
EOF
source /etc/weaselway.conf
runuser -u "$WW_USER" -- env XDG_RUNTIME_DIR="/run/user/$WW_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$WW_UID/bus" systemctl --user daemon-reload
runuser -u "$WW_USER" -- env XDG_RUNTIME_DIR="/run/user/$WW_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$WW_UID/bus" systemctl --user enable --now weaselway-update-check.timer
