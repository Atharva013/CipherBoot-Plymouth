# MODULE 01 — Theme Assets

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**Folder:** `theme/assets/`  
**Files:** Multiple PNGs (frames + progress bar + background)

---

## What This Module Does

This module covers the creation of all **visual assets** used by the Plymouth theme:

1. **Animation Frames** — a sequence of PNG images that play like a flipbook during boot
2. **Progress Bar Sprites** — the visual indicator showing boot progress (0% → 100%)
3. **Signature Overlay** — an optional centered name/handle rendered above the rain
4. **Background Image** — the full-screen base canvas behind the animation

These files are what the user *actually sees*. Everything else (scripts, config) just controls how these files are displayed.

---

## File Specifications

### Animation Frames
- **Format:** PNG, 8-bit palette (PNG8) — optimised for minimal file size
- **Render Resolution:** `960×540` (half of 1080p — Plymouth upscales to native resolution at runtime)
- **Count:** 48 frames (plays at 10fps for a smooth ~4.8 second loop)
- **Naming convention (STRICT):** `frame-0000.png`, `frame-0001.png`, ..., `frame-0047.png`
- **Location:** `theme/assets/frames/`
- **Total size:** ~1.7 MB for the default generated frame set

> **Why half resolution?** Full 1920×1080 24-bit frames are much larger, and Plymouth's script engine must decode them from the initramfs during early boot. At 960×540 with PNG8 palette, each frame stays small and Plymouth's built-in `Scale()` function handles the upscaling.

### Progress Bar
- **Format:** PNG
- **Resolution:** `500×12` pixels (width × height)
- **Two files needed:**
  - `progress_bar_bg.png` — the background/empty bar with thin border
  - `progress_bar_fg.png` — the filled/active portion with gradient (Plymouth crops this based on progress %)
- **Location:** `theme/assets/progress/`

### Background
- **Format:** PNG
- **Resolution:** `960×540` (upscaled by script at runtime)
- **File name:** `background.png`
- **Location:** `theme/assets/`

### Signature Overlay
- **Format:** Transparent PNG
- **Resolution:** `960×540` (full-screen overlay, upscaled by script at runtime)
- **File name:** `signature.png`
- **Location:** `theme/assets/`
- **Text limit:** 16 characters
- **Supported characters:** letters, numbers, spaces, dots, hyphens, and underscores

---

## Design Guidelines (CipherBoot Aesthetic)

The visual identity is **cinematic cyberpunk terminal**:

| Element | Value |
|---|---|
| Primary background colour | `#000000` or `#050508` (near-black) |
| Primary accent colour | `#00FF41` (neon green) |
| Secondary accent | `#00BFFF` or `#00FFFF` for alternate variants |
| Font style in animation | Monospace — mix of ASCII chars, digits, and a few Japanese katakana |
| Animation feel | Falling cipher-rain columns with bright head characters and dim trails |
| Progress bar colour | `#00FF41` on `#0d1a0d` background for the default neon variant |

---

## How to Generate Frames (Using the Python Script)

You do **not** need to draw frames by hand. Use the provided generator:

```bash
# Install dependency
pip install pillow

# Generate all assets (frames + background + progress bar)
python3 scripts/generate_frames.py --all

# Generate assets with a signature overlay
python3 scripts/generate_frames.py --all --signature "Dr. Octopus"

# Generate with a specific variant
python3 scripts/generate_frames.py --all --variant ghost

# Generate a variant with a matching signature overlay
python3 scripts/generate_frames.py --all --variant neon --signature "Dr. Octopus"

# Reproducible output
python3 scripts/generate_frames.py --all --seed 42
```

After running, verify you have 48 files in `theme/assets/frames/`:

```bash
ls theme/assets/frames/frame-*.png | wc -l
# Should output: 48
du -sh theme/assets/frames/
# Should be around 1.7 MB
```

### Font Paths

The generator searches for monospace fonts in common locations:

| Distribution | Font paths searched |
|---|---|
| Ubuntu / Zorin / Mint | `/usr/share/fonts/truetype/dejavu/`, `liberation/`, `ubuntu/`, `freefont/` |
| Arch / EndeavourOS / Manjaro | `/usr/share/fonts/TTF/`, `liberation/`, `noto/`, `gnu-free/` |

---

## Checklist

- [x] `theme/assets/frames/` contains `frame-0000.png` through `frame-0047.png`
- [x] All frames are 960×540 PNG8 (palette mode)
- [x] Total frame payload remains small enough for initramfs use
- [x] `theme/assets/progress/progress_bar_bg.png` exists
- [x] `theme/assets/progress/progress_bar_fg.png` exists
- [x] `theme/assets/background.png` exists
- [x] `theme/assets/signature.png` exists
- [x] Visually reviewed frames — neon cipher rain looks correct
