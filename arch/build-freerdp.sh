#!/usr/bin/env bash
set -euo pipefail
root=${WEASELWAY_BUILD_ROOT:-$HOME/workspace/weaselway-arch}
mkdir -p "$root/src"
cd "$root/src"
archive=freerdp-3.32.2.tar.gz
test -f "$archive" || curl -fL --retry 3 https://codeload.github.com/FreeRDP/FreeRDP/tar.gz/refs/tags/3.32.2 -o "$archive"
echo "9ccb8357bf0188044a460de775c7ea289ca7d2a2a917eca0f0a7c4dc9c8b08ea  $archive" | sha256sum -c -
test -d FreeRDP-3.32.2 || tar -xzf "$archive"
cd FreeRDP-3.32.2
sed -i s/AV_CODEC_ID_PCM_U16LE/AV_CODEC_ID_PCM_S16LE/ libfreerdp/codec/dsp_ffmpeg.c
cmake -S . -B "$root/build/freerdp" -GNinja -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=/opt/weaselway/freerdp -DCMAKE_INSTALL_LIBDIR=lib \
 -DWITH_CLIENT=OFF -DWITH_SERVER=ON -DWITH_PROXY=OFF -DWITH_SHADOW=OFF \
 -DWITH_MANPAGES=OFF -DWITH_X11=OFF -DWITH_WAYLAND=OFF -DWITH_SDL=OFF \
 -DWITH_OPENH264=OFF -DWITH_CAIRO=OFF -DWITH_FUSE=OFF -DWITH_CUPS=OFF \
 -DWITH_PCSC=OFF -DWITH_SAMPLE=OFF -DBUILD_TESTING=OFF
nice -n 10 ninja -C "$root/build/freerdp" -j4
