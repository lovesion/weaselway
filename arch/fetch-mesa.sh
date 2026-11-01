#!/usr/bin/env bash
set -euo pipefail
root=${WEASELWAY_BUILD_ROOT:-$HOME/workspace/weaselway-arch}
mkdir -p "$root/src"
cd "$root/src"
if ! test -d mesa/.git; then
 git -c http.version=HTTP/1.1 clone --depth 1 --filter=blob:none --no-checkout --branch mesa-26.2.1-wsl https://github.com/weaselway/mesa.git mesa
fi
cd mesa
test "$(git rev-parse HEAD)" = e2008be3fa70d4b6e2cc519abb3dfabb58d1e169
git sparse-checkout init --cone
# Split blob retrieval into bounded groups for slow or interrupted connections.
git sparse-checkout set bin build-aux include subprojects src/compiler
git checkout
git sparse-checkout add src/gallium/auxiliary src/gallium/frontends src/gallium/include src/gallium/targets src/gallium/winsys
git sparse-checkout add src/gallium/drivers/d3d12 src/gallium/drivers/llvmpipe src/gallium/drivers/softpipe src/gallium/drivers/zink
git sparse-checkout add src/egl src/gbm src/glx src/mapi src/mesa src/loader src/util
git sparse-checkout add src/vulkan src/microsoft src/drm-shim
git sparse-checkout add src/gtest src/c11 src/android_stub src/amd src/tool src/virtio src/x11
