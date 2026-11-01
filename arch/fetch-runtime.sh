#!/usr/bin/env bash
set -euo pipefail
root=${WEASELWAY_BUILD_ROOT:-$HOME/workspace/weaselway-arch}
kernel=6.18.54.1-microsoft-standard-WSL2
test "$(uname -r)" = "$kernel" || { echo "This recipe is pinned to $kernel; add and verify another module before proceeding." >&2; exit 1; }
mkdir -p "$root/artifacts" "$root/src/dxgdrm-uapi"
cd "$root/artifacts"
curl -fL --retry 3 "https://github.com/weaselway/dxgdrm/releases/download/v1.2.1/dxgdrm-$kernel.tar.gz" -o dxgdrm.tar.gz
curl -fL --retry 3 https://github.com/weaselway/freerdp/releases/download/v1.2.0rc1/freerdp-v1.2.0rc1.zip -o viewer.zip
echo '23f7f42ebeb468e1da4cf60cc89a02cc1dba47607d9821c939a45873b002e42c  dxgdrm.tar.gz' | sha256sum -c -
echo '4a3066d6499eccf07b09c0aeb4524c84de677d8426886bafb1d874dc736adb66  viewer.zip' | sha256sum -c -
curl -fL --retry 3 https://raw.githubusercontent.com/weaselway/dxgdrm/v1.2.1/dxgdrm_drm.h -o "$root/src/dxgdrm-uapi/dxgdrm_drm.h"
