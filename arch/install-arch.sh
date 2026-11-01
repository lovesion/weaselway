#!/usr/bin/env bash
set -euo pipefail
src=${1:?Usage: install-arch.sh CHECKOUT USER}
target_user=${2:?Usage: install-arch.sh CHECKOUT USER}
target_uid=$(id -u "$target_user")
build_root=${3:-$(dirname "$(dirname "$src")")}
prefix=/opt/weaselway
test "$(id -u)" = 0 || { echo 'Run this install step as root.' >&2; exit 1; }
if systemctl is-active --quiet weaselway-session.service; then
 echo 'Stop the Weaselway session before replacing its runtime libraries.' >&2
 exit 1
fi
cd "$build_root/artifacts"
echo '23f7f42ebeb468e1da4cf60cc89a02cc1dba47607d9821c939a45873b002e42c  dxgdrm.tar.gz' | sha256sum -c -
echo '4a3066d6499eccf07b09c0aeb4524c84de677d8426886bafb1d874dc736adb66  viewer.zip' | sha256sum -c -
meson install -C "$build_root/build/mesa" --no-rebuild
cmake --install "$build_root/build/freerdp"
mkdir -p "$prefix/dxgdrm" "$prefix/viewer"
tar -xzf dxgdrm.tar.gz -C "$prefix/dxgdrm"
unzip -qo viewer.zip -d "$prefix/viewer"
install -Dm755 "$src/weaselwayd/weaselwayd" "$prefix/bin/weaselwayd"
install -m755 /usr/bin/kwin_wayland "$prefix/bin/kwin_wayland"
install -Dm755 "$src/libexec/prep-session.sh" "$prefix/libexec/prep-session.sh"
for name in ww-start-session ww-start-viewer; do
 install -Dm755 "$src/bin/$name.sh" "$prefix/libexec/$name"
done
sed -i 's/\r$//' "$prefix/libexec/prep-session.sh" "$prefix/libexec/ww-start-session" "$prefix/libexec/ww-start-viewer"
# Do not propagate the upstream WebKit sandbox-disable workaround.
sed -i '/--property=Environment=WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1/d' "$prefix/libexec/ww-start-session"
sed -i '/    \/microphone/d' "$prefix/libexec/ww-start-viewer"
install -Dm644 "$prefix/dxgdrm/lib/udev/rules.d/99-dxgdrm.rules" /etc/udev/rules.d/99-dxgdrm.rules
cat > /etc/udev/rules.d/70-weaselway-uinput.rules <<'EOF'
KERNEL=="uinput", SUBSYSTEM=="misc", GROUP="input", MODE="0660"
EOF
usermod -aG render,video,input "$target_user"
install -Dm644 "$src/pipewire/pipewire.conf.d/10-weaselway-rdp-audio.conf" /etc/pipewire/pipewire.conf.d/10-weaselway-rdp-audio.conf
cat > "$prefix/libexec/environment" <<'EOF'
export LD_LIBRARY_PATH=/opt/weaselway/freerdp/lib:/opt/weaselway/mesa/lib:/usr/lib/wsl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/weaselway/mesa/share/glvnd/egl_vendor.d/50_mesa.json
export LIBGL_DRIVERS_PATH=/opt/weaselway/mesa/lib/dri
export LIBVA_DRIVERS_PATH=/opt/weaselway/mesa/lib/dri
export GALLIUM_DRIVER=d3d12
export LIBVA_DRIVER_NAME=d3d12
export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
export WEASELWAY_DEFAULT_SESSION=plasma
export WEASELWAY_VSOCK_PORT=3389
export WEASELWAY_VIEWER=/opt/weaselway/viewer/sdl-freerdp.exe
export PATH=/opt/weaselway/bin:/usr/local/bin:/usr/bin
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export KWIN_DRM_DEVICES=/dev/dri/by-path/platform-dxgdrm-card
unset PULSE_SERVER
EOF
sed -i "s@/run/user/1000@/run/user/$target_uid@g" "$prefix/libexec/environment"
printf 'WW_USER=%q\nWW_UID=%q\n' "$target_user" "$target_uid" > /etc/weaselway.conf
# Scope the private Mesa to this desktop; do not replace Arch system libraries.
cat > /usr/local/bin/ww-run <<'EOF'
#!/usr/bin/env bash
source /opt/weaselway/libexec/environment
exec "$@"
EOF
chmod 755 /usr/local/bin/ww-run
for name in ww-start-session ww-start-viewer; do
 printf '#!/usr/bin/env bash\nsource /opt/weaselway/libexec/environment\nexec /opt/weaselway/libexec/%s "$@"\n' "$name" > "/usr/local/bin/$name"
 chmod 755 "/usr/local/bin/$name"
done
cat > /etc/systemd/system/weaselway-prep.service <<'EOF'
[Unit]
Description=Weaselway Arch host preparation
After=local-fs.target wslg.service systemd-udevd.service
Before=systemd-logind.service
[Service]
Type=oneshot
RemainAfterExit=yes
Environment=DXGDRM_ROOT=/opt/weaselway/dxgdrm
ExecStart=/opt/weaselway/libexec/prep-session.sh
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/user/weaselwayd.service <<'EOF'
[Unit]
Description=Weaselway Arch display and RDP server
[Service]
ExecStart=/usr/local/bin/ww-run /opt/weaselway/bin/weaselwayd
Restart=on-failure
RestartSec=3
EOF
mkdir -p /etc/systemd/user/plasma-kwin_wayland.service.d
cat > /etc/systemd/user/plasma-kwin_wayland.service.d/weaselway.conf <<'EOF'
[Service]
Environment=PATH=/opt/weaselway/bin:/usr/local/bin:/usr/bin
Environment=LD_LIBRARY_PATH=/opt/weaselway/mesa/lib:/usr/lib/wsl/lib
Environment=__EGL_VENDOR_LIBRARY_FILENAMES=/opt/weaselway/mesa/share/glvnd/egl_vendor.d/50_mesa.json
Environment=LIBGL_DRIVERS_PATH=/opt/weaselway/mesa/lib/dri
Environment=GALLIUM_DRIVER=d3d12
Environment=MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
Environment=KWIN_DRM_DEVICES=/dev/dri/by-path/platform-dxgdrm-card
EOF
systemctl daemon-reload
udevadm control --reload
systemctl enable weaselway-prep.service
systemctl start weaselway-prep.service
udevadm trigger --subsystem-match=drm
udevadm trigger --subsystem-match=misc
loginctl enable-linger "$target_user"
install -m755 "$src/arch/control-session.sh" "$prefix/libexec/control-session"
install -m755 "$src/arch/ww-app" /usr/local/bin/ww-app
systemctl --global mask wslg-session.service
bash "$src/arch/maintenance-install.sh"
