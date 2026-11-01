#!/usr/bin/env bash
set -euo pipefail
root=${WEASELWAY_BUILD_ROOT:-$HOME/workspace/weaselway-arch}
src=$root/src/mesa
if test -f "$src/.source-revision"; then
 test "$(cat "$src/.source-revision")" = e2008be3fa70d4b6e2cc519abb3dfabb58d1e169
else
 test "$(git -C "$src" rev-parse HEAD)" = e2008be3fa70d4b6e2cc519abb3dfabb58d1e169
fi
compat_patch=$(cd "$(dirname "$0")" && pwd)/mesa-directx-c-compat.patch
if git -C "$src" apply --check "$compat_patch" 2>/dev/null; then
 git -C "$src" apply "$compat_patch"
else
 git -C "$src" apply --reverse --check "$compat_patch"
fi
setup_args=()
test ! -f "$root/build/mesa/meson-private/coredata.dat" || setup_args+=(--reconfigure)
meson setup "${setup_args[@]}" "$root/build/mesa" "$src" \
 --prefix=/opt/weaselway/mesa --libdir=lib --buildtype=release \
 -Dglvnd=enabled -Dplatforms=x11,wayland \
 -Dgallium-drivers=d3d12,llvmpipe,softpipe,zink \
 -Dvulkan-drivers=microsoft-experimental,swrast \
 -Dgallium-d3d12-graphics=enabled -Dgallium-d3d12-video=enabled \
 -Dgallium-va=enabled -Dvideo-codecs=all -Dgallium-rusticl=false \
 -Dteflon=false -Dintel-rt=disabled -Dtools=
# Keep RAM use and host contention bounded on the shared laptop.
nice -n 10 ninja -C "$root/build/mesa" -j4
