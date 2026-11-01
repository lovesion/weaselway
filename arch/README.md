# Arch Linux adaptation (experimental)

This fork preserves [weaselway/weaselway](https://github.com/weaselway/weaselway) and its MIT license. Arch integration is being developed on the `archlinux` branch.

The intended stack is stock KDE Plasma/KWin, a private build of Weaselway's patched Mesa, an exact-kernel dxgdrm module, weaselwayd, and the upstream Windows FreeRDP viewer. Frames use GPU readback and shared memory: this is **not end-to-end zero-copy**.

## Verified so far

- Microsoft WSL kernel `6.18.54.1-microsoft-standard-WSL2` loads official dxgdrm v1.2.1 and creates display/render nodes.
- RTX 4070 Laptop executes a CUDA driver-API test kernel correctly with dxgdrm loaded.
- Arch Plasma/KWin 6.8.2 is installed. weaselwayd builds against Arch FreeRDP 3.32.2 headers; all eight upstream format tests pass.
- The WSLg DAX shared-memory share mounts; PipeWire creates a Remote Desktop Audio sink.

These checks do not yet establish a usable desktop, correct final pixels, keyboard/mouse delivery, audible sound, frame rate, latency, or restart recovery. Acceptance tests are in progress.

## Source pins

| Component | Version |
| --- | --- |
| Weaselway | `d70a6344f04bf516b4596860a1321d5fdf06a377` |
| Mesa | `e2008be3fa70d4b6e2cc519abb3dfabb58d1e169` |
| dxgdrm | `v1.2.1` |
| Windows viewer | `v1.2.0rc1` |
| Linux FreeRDP | `3.32.2` plus the signed PCM16 correction |

Private Mesa and FreeRDP builds live under `/opt/weaselway`, without replacing Arch libraries. No Windows input injection or desktop shortcut is required.

## Licensing

Integration code follows this repository's MIT license. Dependencies retain their licenses: dxgdrm declares GPL-2.0, FreeRDP is Apache-2.0, Mesa has per-file licenses, and KDE retains its upstream licenses. Redistributors must include required notices and corresponding source where applicable. This fork does not relicense dependencies.
