# MODULE 07 — Multi-Distro Compatibility

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**File:** `scripts/detect_distro.sh`

## What This Module Does

Provides the distro detection utility sourced by `install.sh` and `uninstall.sh`. Reads `/etc/os-release`, identifies the distribution, and exports `DISTRO_NAME` and `DISTRO_FAMILY` variables.

## Supported Distros

### Ubuntu Family (`DISTRO_FAMILY="ubuntu"`)

| `/etc/os-release` ID | Distro |
|---|---|
| `ubuntu` | Ubuntu |
| `zorin` | Zorin OS |
| `pop` | Pop!_OS |
| `linuxmint` | Linux Mint |
| `elementary` | elementary OS |
| *(fallback)* | Any distro with `ID_LIKE=ubuntu` |

### Arch Family (`DISTRO_FAMILY="arch"`)

| `/etc/os-release` ID | Distro |
|---|---|
| `arch` | Arch Linux |
| `endeavouros` | EndeavourOS |
| `manjaro` | Manjaro |
| `garuda` | Garuda Linux |
| `cachyos` | CachyOS |
| *(fallback)* | Any distro with `ID_LIKE=arch` |

## How Family Detection Works

```
1. Read /etc/os-release
2. Check $ID against known distros → set DISTRO_FAMILY
3. If no match, check $ID_LIKE for "ubuntu" or "arch" → set DISTRO_FAMILY with warning
4. If neither matches → exit with clear error + GitHub Issues link
```

## Exported Variables

| Variable | Example Value | Used By |
|---|---|---|
| `DISTRO_NAME` | "Zorin OS", "Arch Linux" | Banner display in install/uninstall |
| `DISTRO_FAMILY` | "ubuntu" or "arch" | Branching logic for apt/pacman, initramfs/mkinitcpio |

## Checklist

- [x] `scripts/detect_distro.sh` created
- [x] All Ubuntu-based distros detected correctly
- [x] All Arch-based distros detected correctly
- [x] Fallback via `ID_LIKE` works for unknown derivatives
- [x] Unknown distro exits with clear error and GitHub Issues link
