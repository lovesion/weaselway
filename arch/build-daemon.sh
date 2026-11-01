#!/usr/bin/env bash
set -euo pipefail
root=${WEASELWAY_BUILD_ROOT:-$HOME/workspace/weaselway-arch}
src=${1:?Usage: build-daemon.sh WEASELWAY_CHECKOUT}
make -C "$src/weaselwayd" -j4 DXGDRM_INCLUDE="$root/src/dxgdrm-uapi" weaselwayd check
