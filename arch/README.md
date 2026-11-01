# Weaselway on Arch Linux (experimental)

An Arch adaptation of [weaselway/weaselway](https://github.com/weaselway/weaselway),
preserving its MIT license and upstream NixOS/Ubuntu workflows. This branch
targets an existing `archlinux` WSL distribution and KDE Plasma, with no display
manager or desktop shortcut.

## What follows Arch updates

KDE Plasma and KWin remain Arch's official packages. No KWin source patch is
required in the tested configuration. On every session start, the controller
refreshes a byte-identical copy of `/usr/bin/kwin_wayland` under
`/opt/weaselway/bin`. The copy omits the original's `cap_sys_nice` file capability,
so the loader retains the private Mesa library path. The stock KWin wrapper
finds it through its service's PATH. This can lose realtime scheduling privileges;
it is not a separately maintained KWin fork. System libraries remain dependencies,
and major upgrades still require acceptance tests.

Weaselway's Mesa fork, dxgdrm, daemon and viewer remain independently pinned.
Frames involve GPU readback and shared memory: **not end-to-end zero-copy**.
The current stock KWin path reads back the entire output for each changed frame.
Upstream KWin damage patches may reduce that cost, but are not installed here.

## Verified on 2026-11-01

| Check | Result |
| --- | --- |
| Kernel/module | Microsoft `6.18.54.1-microsoft-standard-WSL2`, official dxgdrm v1.2.1 loads; module reports an out-of-tree taint and a BTF warning |
| GPU | RTX 4070 Laptop GPU, Windows driver 595.71, guest nvidia-smi 595.45.03 |
| CUDA | Actual driver-API PTX kernel returns 42, including while KDE is running |
| OpenGL | Private Mesa reports OpenGL 4.6 and ES 3.1 on D3D12 NVIDIA; KWin uses ES 3.1 |
| Desktop | Full Plasma/KWin 6.8.2 visible in Windows viewer; no failed user units at inspection |
| Input/resize | User confirmed mouse clicks, keyboard input and viewer resizing; diagnostic application logged mouse and text-edit events |
| Vulkan | Dozen identifies the NVIDIA GPU, reports API 1.2.354; a Wayland vkcube run exits 0. **Non-conformant, testing-only implementation**, not a game compatibility claim |
| Audio | PipeWire sink and RDP playback channel exist; PCM16 sample probe matches exactly after the FreeRDP fix. Actual audible playback remains unconfirmed by the user |
| Recovery | Killing the viewer preserves KDE/daemon. Terminating only the Arch distro and restarting through the Windows launcher restores module, KDE, viewer connection and frame delivery |

The 1280x768 dynamic test recorded approximately 48-121 viewer-counted frames/s
in its active sample periods, including startup/exit transitions; idle periods
intentionally produce fewer updates. Bridge five-second summaries reported
roughly 2.2-3.8 ms per full-frame readback in the inspected pre-restart log.
Viewer upload/presentation stage counters are separate measurements. None is an
input-to-photon latency measurement, a fixed sustained desktop benchmark, or a
guarantee for another resolution/workload. The configured 165 Hz mode is not a
claim of 165 delivered frames/s.

**165 Hz is a requirement for this deployment.** No 60 Hz workaround is applied.
Stable delivery of 165 frames/s remains an open acceptance criterion; the
foreground/occlusion-controlled measurement was deferred by the user. Initial
background CPU sampling on 24 logical processors observed approximately 0-0.01%
whole-machine CPU in the Windows viewer at idle and 0.75% during the animated
test, while WSL as a whole averaged 6.47% during that test. Other host workloads
were active, so these are process measurements rather than a clean system-wide
benchmark. See `Measure-WeaselwayCpu.ps1` for reproducible sampling.

Microphone forwarding is omitted by default. Video encode/decode, NVENC/NVDEC,
HDR, long-duration stability and game compatibility have not been accepted.
The WebKit sandbox-disable workaround from the upstream launcher is not enabled.

## Pins and local patches

See [versions.json](versions.json) for exact versions and release archive SHA-256
digests. Mesa is based on `e2008be3fa70d4b6e2cc519abb3dfabb58d1e169`.

- [mesa-directx-c-compat.patch](mesa-directx-c-compat.patch): C forward declaration
  required by Arch DirectX-Headers 1.721.2. The Mesa runtime behavior is unchanged.
- Linux FreeRDP 3.32.2 uses the upstream `PCM_U16LE` → `PCM_S16LE` correction,
  preserved in [build-freerdp.sh](build-freerdp.sh). The system package fails the
  signed-sample probe; the private build passes.

## Build recipe

These scripts record the tested integration. The combined installer has not
been independently accepted on a second clean Arch installation. Read the
scripts before using them on another system.

Prerequisites: WSL2 x86_64, systemd, WSLg enabled, and the exact supported kernel
above. WSL shares its kernel across distros; inspect other workloads before any
global kernel setting or `wsl --shutdown`. Do not replace a custom kernel
without determining why it is installed.

Install a coherent Arch package set, rather than mixing stale repository metadata:

```sh
sudo pacman -Syu --needed base-devel git curl unzip cmake meson ninja pkgconf \
 plasma-desktop plasma-pa kscreen konsole dolphin xorg-xwayland \
 xdg-desktop-portal-kde pipewire-pulse wireplumber freerdp libnotify \
 python-mako python-pyyaml python-packaging python-ply python-pycparser \
 llvm clang rust bindgen directx-headers glslang spirv-llvm-translator libclc \
 libva libvdpau libdrm libglvnd wayland-protocols mesa-utils vulkan-tools
mkdir -p ~/workspace/weaselway-arch/src
git clone --branch archlinux https://github.com/lovesion/weaselway.git \
 ~/workspace/weaselway-arch/src/weaselway
cd ~/workspace/weaselway-arch/src/weaselway
bash arch/fetch-runtime.sh
bash arch/fetch-mesa.sh
bash arch/build-mesa.sh
bash arch/build-freerdp.sh
bash arch/build-daemon.sh "$PWD"
sudo bash arch/install-arch.sh "$PWD" "$USER"
```

Builds use four workers at reduced scheduling priority. Set
`WEASELWAY_BUILD_ROOT` consistently to use another build directory; pass that
directory as the install script's third argument. The private runtimes go under
`/opt/weaselway`, without replacing Arch's Mesa/FreeRDP libraries.

The installer configures device groups, prep/user services and PipeWire, and
masks `wslg-session.service` so it cannot replace PipeWire's Pulse socket.
Restart the Arch distro after initial installation for new group membership.
When replacing a loaded kernel module, a complete WSL restart is required.

## Command entry points

From Windows PowerShell, use [Weaselway.ps1](Weaselway.ps1):

```powershell
.\Weaselway.ps1 start
.\Weaselway.ps1 viewer
.\Weaselway.ps1 status
.\Weaselway.ps1 stop
```

No administrator Windows session is required. The launcher runs only the Linux
session controller as root, then runs the desktop as the configured normal
user. Closing the viewer leaves the session running. `stop` ends the KDE session.

From Windows or a WSL shell, open an application inside this KDE session:

```powershell
wsl -d archlinux -- ww-app konsole
```

Use `ww-app` rather than inherited WSLg display variables. Experimental Vulkan
can be selected per application with
`VK_DRIVER_FILES=/opt/weaselway/mesa/share/vulkan/icd.d/dzn_icd.x86_64.json`.
It is deliberately not selected globally.

## Maintenance and recovery

The read-only user timer checks upstream source changes, local package versions
and exact-kernel module availability while Arch is running. It never upgrades
anything and notifies only on a newly changed actionable state.

```sh
systemctl --user start weaselway-update-check.service
cat ~/.local/state/weaselway/update-status.json
journalctl --user -u weaselwayd
journalctl --user -u plasma-kwin_wayland
systemctl status weaselway-prep weaselway-session
```

Keep source pins and patches with a known-good runtime before updating. Stop
the desktop before replacing private libraries. Test render, input, resize,
audio and reconnect again after upgrades. A missing module for a new WSL kernel
is a compatibility failure, not a reason to force-load an older module.

## Licensing

Integration code follows the repository's MIT license. Dependencies retain their
licenses: dxgdrm GPL-2.0 (UAPI has Linux-syscall-note), FreeRDP Apache-2.0, Mesa
per-file licenses, and KDE its upstream licenses. Binary redistribution must
include appropriate notices and corresponding source where required. This
branch publishes recipes and patches, not relicensed dependency binaries.
