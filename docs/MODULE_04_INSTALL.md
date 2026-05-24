# MODULE 04 — Install Script

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**File:** `install.sh`

---

## What This Module Does

`install.sh` is what the user runs. It handles:

1. Checking it's being run as root (`sudo`)
2. Detecting the user's Linux distribution (Ubuntu-based or Arch-based)
3. Checking Plymouth is installed (and installing it if not — via `apt` or `pacman`)
4. Copying theme files to the correct system directory
5. Optionally generating a centered boot signature overlay
6. Registering the theme with Plymouth (`plymouth-set-default-theme` or `update-alternatives`)
7. Configuring GRUB for a smoother splash handoff (safe — only adds missing settings)
8. Rebuilding initramfs (`update-initramfs` on Ubuntu, `mkinitcpio` on Arch)
9. Printing a clear success message

---

## Distro-Specific Behaviour

| Step | Ubuntu-based | Arch-based |
|---|---|---|
| Install Plymouth | `apt-get install plymouth` | `pacman -S plymouth` |
| Register theme | `update-alternatives` or `plymouth-set-default-theme` | `plymouth-set-default-theme` |
| Update GRUB | `update-grub` | `grub-mkconfig -o /boot/grub/grub.cfg` |
| Rebuild initrd | `update-initramfs -u` | `mkinitcpio -P` |
| Extra setup | — | Auto-adds `plymouth` to `mkinitcpio` HOOKS |

Neon is the default variant. For non-default variants, the installer generates the selected variant's assets in `/tmp` before copying them into the Plymouth theme directory. This keeps the repository's default assets unchanged while making `--variant ghost` and `--variant cipher` visually real.

If a boot signature is provided, the installer also regenerates assets in `/tmp` so the signature colour matches the selected variant.

---

## GRUB Configuration

The install script configures GRUB to reduce the black screen gap between GRUB and Plymouth where the firmware, kernel, and GPU driver allow it:

### What it does:
1. **Backs up** `/etc/default/grub` to `/etc/default/grub.cipherboot.bak` (only on first install)
2. **Sets** `GRUB_GFXMODE=auto` — only if it's commented out or missing
3. **Adds** `GRUB_GFXPAYLOAD_LINUX=keep` — only if missing
4. **Ensures** `quiet splash` is in `GRUB_CMDLINE_LINUX_DEFAULT` — only if missing
5. **Adds** GPU modesetting hints such as `i915.modeset=1` or `nvidia-drm.modeset=1` when matching hardware is detected
6. **Adds** `vt.handoff=7` if no `vt.handoff` value is already present

### What it does NOT do:
- ❌ Never overwrites existing user-set values
- ❌ Never removes any lines
- ❌ Never changes GRUB theme settings
- ❌ Never hides the GRUB menu or changes GRUB timeout behaviour
- ❌ Never modifies anything else in the file
- ❌ Never changes the default OS
- ❌ Never removes existing boot parameters

### Skip GRUB configuration:
```bash
sudo ./install.sh --no-grub
```

---

## Command-Line Options

| Flag | Description |
|---|---|
| `--variant neon\|ghost\|cipher` | Choose colour variant (default: neon) |
| `--signature TEXT` | Add a centered boot signature, max 16 characters |
| `--no-signature` | Disable the interactive signature prompt |
| `--no-grub` | Skip GRUB configuration entirely |
| `--help`, `-h` | Show usage |

---

## Arch Linux: mkinitcpio Hook

On Arch-based systems, the install script automatically adds the `plymouth` hook to `/etc/mkinitcpio.conf` if it's not already present. It inserts `plymouth` after `base` in the HOOKS array:

```bash
HOOKS=(base plymouth udev autodetect modconf block filesystems keyboard fsck)
```

---

## Checklist

- [x] `install.sh` created at repo root
- [x] Root check works
- [x] Distro detection works for Ubuntu and Arch families
- [x] Plymouth auto-install via apt/pacman
- [x] All theme files copied to correct locations
- [x] Theme registered with Plymouth
- [x] GRUB configured safely with backup
- [x] initramfs rebuilt (update-initramfs / mkinitcpio)
- [x] --no-grub flag functional
- [x] --variant flag functional
- [x] --signature and --no-signature flags functional
