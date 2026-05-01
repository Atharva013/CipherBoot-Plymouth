# MODULE 06 — Preview Script (No Reboot Required)

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**File:** `preview.sh`

## What This Module Does

Users can see the theme on their desktop **without rebooting**. This is a unique feature of CipherBoot vs most Plymouth themes. Plymouth's built-in test mode runs the theme inside a window using `plymouthd --no-daemon`.

## Two Modes

| Mode | Command | Description |
|---|---|---|
| Simple preview | `./preview.sh --simple` | Opens `frame-0000.png` in image viewer; most reliable |
| Full preview | `sudo ./preview.sh` | Runs Plymouth in a test window when `plymouth-x11` and the desktop/display stack support it |

## Image Viewer Support

The simple mode does not need sudo. It tries these viewers in order (covers both Ubuntu and Arch desktops):

`eog` → `feh` → `gwenview` → `sxiv` → `imv` → `display` → `xdg-open`

## Full Preview Requirements

Full preview is best effort because Plymouth's real job is owning the boot framebuffer, not rendering inside an already-running desktop session. On Ubuntu-based systems, install the X11 renderer first:

```bash
sudo apt install plymouth-x11
sudo ./preview.sh
```

The script writes debug output to `/tmp/cipherboot_preview.log` when full preview cannot start.

## Checklist

- [x] `preview.sh` created at repo root
- [x] Simple mode works with common Ubuntu and Arch image viewers
- [x] Full mode opens a Plymouth window on compatible X11/Wayland sessions
- [x] Progress bar fills correctly during preview
- [x] Script exits cleanly (no zombie `plymouthd` process)
