#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" = 0 || { echo 'Run through: wsl -d archlinux -u root -- /opt/weaselway/libexec/control-session start|stop|status'; exit 1; }
source /opt/weaselway/libexec/environment
source /etc/weaselway.conf
case ${1:-start} in
stop) systemctl stop weaselway-session.service; exit;;
status) systemctl --no-pager status weaselway-session.service; exit;;
start) ;;
*) exit 2;;
esac
if systemctl is-active --quiet weaselway-session.service; then exit 0; fi
systemctl start weaselway-prep.service
systemctl start "user@$WW_UID.service"
test -e "$KWIN_DRM_DEVICES"
# A byte-identical, capability-free copy keeps the private library search path.
# Refresh on every start so Arch KWin updates cannot leave a stale executable.
install -m755 /usr/bin/kwin_wayland /opt/weaselway/bin/kwin_wayland
runuser -u "$WW_USER" -- systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY GNOME_SETUP_DISPLAY
runuser -u "$WW_USER" -- systemctl --user import-environment LD_LIBRARY_PATH __EGL_VENDOR_LIBRARY_FILENAMES LIBGL_DRIVERS_PATH LIBVA_DRIVERS_PATH GALLIUM_DRIVER LIBVA_DRIVER_NAME MESA_D3D12_DEFAULT_ADAPTER_NAME WEASELWAY_VSOCK_PORT KWIN_DRM_DEVICES
runuser -u "$WW_USER" -- systemctl --user daemon-reload
runuser -u "$WW_USER" -- systemctl --user start pipewire pipewire-pulse wireplumber weaselwayd
systemctl reset-failed weaselway-session.service 2>/dev/null || true
chvt 7
systemd-run --unit=weaselway-session --collect \
 -p "User=$WW_USER" -p PAMName=login \
 -p TTYPath=/dev/tty7 -p StandardInput=tty -p TTYReset=yes -p TTYVHangup=yes \
 -p StandardOutput=journal -p StandardError=journal \
 -p Environment=XDG_SESSION_TYPE=wayland -p Environment=XDG_SESSION_CLASS=user \
 -p Environment=XDG_SEAT=seat0 -p Environment=XDG_VTNR=7 \
 -p Environment=XDG_CURRENT_DESKTOP=KDE -p Environment=XDG_SESSION_DESKTOP=KDE \
 -p "Environment=XDG_RUNTIME_DIR=/run/user/$WW_UID" \
 -p "Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$WW_UID/bus" \
 -p Environment=PATH=/usr/local/bin:/usr/bin \
 /usr/local/bin/ww-run /usr/bin/startplasma-wayland
