# MODULE 05 — Uninstall Script

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**File:** `uninstall.sh`

## What This Module Does

`uninstall.sh` cleanly removes CipherBoot and restores the user's system to its previous state. This is a **feature most themes skip** — having it makes CipherBoot stand out as a professional, user-respecting project.

## Logic Flow

1. Check for root (sudo)
2. Detect distro (Ubuntu-based or Arch-based)
3. Check if CipherBoot is actually installed
4. Reset Plymouth to system default theme
   - Ubuntu: `bgrt` or `text` via `update-alternatives` / `plymouth-set-default-theme`
   - Arch: `spinner` or `text` via `plymouth-set-default-theme`
5. Remove `/etc/plymouth/plymouthd.conf`
6. **Restore original GRUB config** from `/etc/default/grub.cipherboot.bak` (if it exists)
7. Regenerate GRUB config (`update-grub` or `grub-mkconfig`)
8. Delete `/usr/share/plymouth/themes/CipherBoot/`
9. Rebuild initramfs (`update-initramfs` or `mkinitcpio`)
10. Confirm success

## GRUB Restoration

The uninstall script restores the exact GRUB config that existed before CipherBoot was installed:
- Copies `/etc/default/grub.cipherboot.bak` back to `/etc/default/grub`
- Removes the backup file
- Runs `update-grub` or `grub-mkconfig` to regenerate
- If no backup exists, it means CipherBoot didn't modify GRUB — nothing to restore

## Checklist

- [x] `uninstall.sh` created at repo root
- [x] Tested: uninstall runs cleanly after install
- [x] GRUB config restored from backup
- [x] Default theme is correctly restored on reboot
- [x] Works on both Ubuntu-based and Arch-based systems
