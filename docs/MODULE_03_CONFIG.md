# MODULE 03 — Theme Configuration File

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**Folder:** `theme/`  
**Files:** `CipherBoot.plymouth`, `CipherBoot-ghost.plymouth`, `CipherBoot-neon.plymouth`

---

## What This Module Does

The `.plymouth` file is a **plain text descriptor** that tells Plymouth:
- The theme's name and description
- Which script file to use
- What kind of module to use (we use `script` — the most flexible type)

It's a small file but **required** — without it Plymouth won't recognise the theme at all.

---

## File: `theme/CipherBoot.plymouth`

```ini
[Plymouth Theme]
Name=CipherBoot
Description=CipherBoot Cipher variant — teal cipher-rain animation on deep black background.
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/CipherBoot
ScriptFile=/usr/share/plymouth/themes/CipherBoot/CipherBoot.script
```

### Field Explanations

| Field | Purpose |
|---|---|
| `Name` | Display name shown in `plymouth-set-default-theme --list` |
| `Description` | Human-readable description |
| `ModuleName=script` | Tells Plymouth to use the `script` plugin (required for custom animations) |
| `ImageDir` | Absolute path where Plymouth looks for all image assets at runtime |
| `ScriptFile` | Absolute path to the `.script` animation file |

> ⚠️ **Important:** The paths must be **absolute paths** pointing to where `install.sh` copies the files (`/usr/share/plymouth/themes/CipherBoot/`). This path is the same on both Ubuntu-based and Arch-based systems. Do not use relative paths.

---

## Variants

Three `.plymouth` files exist for the visual variants:

```
theme/
├── CipherBoot.plymouth          # Cipher variant descriptor
├── CipherBoot-ghost.plymouth    # Ghost variant
└── CipherBoot-neon.plymouth     # Neon variant (default install)
```

All variants share the same installed `ImageDir` and `ScriptFile`. Neon is the default install. During install, `install.sh --variant <name>` generates non-default variant frame, background, progress, and signature assets into a temporary directory and then copies those assets into `/usr/share/plymouth/themes/CipherBoot/`.

---

## Checklist

- [x] `theme/CipherBoot.plymouth` created with correct content
- [x] `theme/CipherBoot-ghost.plymouth` created
- [x] `theme/CipherBoot-neon.plymouth` created
- [x] All paths in `.plymouth` files match the install destination
- [x] Works on both Ubuntu-based and Arch-based systems (same path)
