#!/usr/bin/env python3
"""
generate_frames.py — CipherBoot Asset Generator
Author: Atharva Jadhav
License: Apache-2.0

Generates ALL visual assets needed by the CipherBoot Plymouth theme:
  1. Animation frames     → theme/assets/frames/frame-0000.png ... frame-0047.png
  2. background.png       → theme/assets/background.png
  3. progress_bar_bg.png  → theme/assets/progress/progress_bar_bg.png
  4. progress_bar_fg.png  → theme/assets/progress/progress_bar_fg.png

Frames are rendered at half resolution (960×540) and upscaled by the Plymouth
script at runtime. This keeps total asset payload small and eliminates
animation lag during early boot I/O.

Usage:
    python3 scripts/generate_frames.py --all              (recommended — generates everything)
    python3 scripts/generate_frames.py --all --variant ghost
    python3 scripts/generate_frames.py --all --variant neon
    python3 scripts/generate_frames.py --frames 48 --color "#00FF00"
    python3 scripts/generate_frames.py --all --seed 42    (reproducible output)
"""

import argparse
import random
import string
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ Pillow not installed.")
    print("   Install it using one of these methods:")
    print("   pip install pillow")
    print("   python3 -m pip install pillow")
    print("   Or create a virtual environment first:")
    print("   python3 -m venv .venv && source .venv/bin/activate && pip install pillow")
    raise SystemExit(1)


# ─── Variant Colour Presets ───────────────────────────────────────────────────

VARIANTS = {
    "cipher": {
        "rain_color":   "#00FFFF",
        "bg_color":     "#000000",
        "bar_bg_color": "#1a1a2e",
        "bar_fg_color": "#00FFFF",
    },
    "ghost": {
        "rain_color":   "#00BFFF",
        "bg_color":     "#050510",
        "bar_bg_color": "#0a0a1a",
        "bar_fg_color": "#00BFFF",
    },
    "neon": {
        "rain_color":   "#00FF41",
        "bg_color":     "#000000",
        "bar_bg_color": "#0d1a0d",
        "bar_fg_color": "#00FF41",
    },
}

# Character set: ASCII uppercase + digits + symbols + Japanese katakana
CHARSET = (
    string.ascii_uppercase
    + string.digits
    + "!@#$%^&*<>?/|\\{}[]~="
    + "アイウエオカキクケコサシスセソ"
)

BAR_WIDTH    = 500
BAR_HEIGHT   = 12
FONT_SIZE    = 14          # Smaller font for half-res canvas
COL_SPACING  = 16          # Tighter columns at half-res


# ─── Helpers ──────────────────────────────────────────────────────────────────

def hex_to_rgb(h: str) -> tuple:
    """Convert a hex colour string (#RRGGBB) to an (R, G, B) tuple."""
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def blend(fg: tuple, alpha: float, bg: tuple) -> tuple:
    """Alpha-blend a foreground colour over a background colour."""
    return tuple(int(f * alpha + b * (1.0 - alpha)) for f, b in zip(fg, bg))


def load_font(size: int):
    """Try to load a monospace TrueType font from common system paths."""
    paths = [
        # Debian / Ubuntu / Zorin
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf",
        "/usr/share/fonts/truetype/freefont/FreeMono.ttf",
        # Arch Linux
        "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
        "/usr/share/fonts/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/noto/NotoSansMono-Regular.ttf",
        "/usr/share/fonts/gnu-free/FreeMono.ttf",
    ]
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except IOError:
            continue
    print("   ⚠️  No monospace font found — using PIL default (smaller text)")
    return ImageFont.load_default()


# ─── Generators ───────────────────────────────────────────────────────────────

def make_background(width, height, bg_color, out_dir):
    """Generate a full-screen background with a subtle vignette effect."""
    print("🖼️  Generating background.png ...")
    img = Image.new("RGB", (width, height), color=bg_color)

    # Subtle vignette — darken edges for depth
    draw   = ImageDraw.Draw(img)
    bg_rgb = hex_to_rgb(bg_color)
    steps  = 40
    for i in range(steps):
        margin = i * 14
        if margin >= min(width, height) // 2:
            break
        darkness = (steps - i) / steps * 0.18
        edge_col = blend((0, 0, 0), darkness, bg_rgb)
        draw.rectangle(
            [margin, margin, width - margin - 1, height - margin - 1],
            outline=edge_col
        )

    path = out_dir / "background.png"
    img.save(path, "PNG")
    print(f"   ✅ {path}")


def make_progress_bars(bar_bg, bar_fg, out_dir):
    """Generate progress bar background and foreground sprites."""
    print("📊 Generating progress bar assets ...")
    fg_rgb = hex_to_rgb(bar_fg)
    bg_rgb = hex_to_rgb(bar_bg)

    # Empty background bar with a thin border
    bg_img  = Image.new("RGB", (BAR_WIDTH, BAR_HEIGHT), color=bar_bg)
    bg_draw = ImageDraw.Draw(bg_img)
    bg_draw.rectangle([0, 0, BAR_WIDTH - 1, BAR_HEIGHT - 1], outline=bar_fg)
    bg_img.save(out_dir / "progress_bar_bg.png", "PNG")
    print(f"   ✅ {out_dir / 'progress_bar_bg.png'}")

    # Filled foreground bar with a left-to-right brightness gradient
    fg_img  = Image.new("RGB", (BAR_WIDTH, BAR_HEIGHT), color=bar_bg)
    fg_draw = ImageDraw.Draw(fg_img)
    for x in range(BAR_WIDTH):
        t     = x / BAR_WIDTH
        alpha = 0.6 + 0.4 * t
        col   = blend(fg_rgb, min(alpha, 1.0), bg_rgb)
        fg_draw.line([(x, 1), (x, BAR_HEIGHT - 2)], fill=col)
    fg_draw.rectangle([0, 0, BAR_WIDTH - 1, BAR_HEIGHT - 1], outline=bar_fg)
    fg_img.save(out_dir / "progress_bar_fg.png", "PNG")
    print(f"   ✅ {out_dir / 'progress_bar_fg.png'}")


def make_frames(width, height, frame_count, rain_color, bg_color, frames_dir):
    """
    Generate cipher rain animation frames at half resolution.

    Features:
      - Glow effect on head characters (white-tinted)
      - Random character flicker for a living feel
      - Varying column opacity for parallax-like depth
      - Optimised PNG8 palette output for minimal file size
    """
    print(f"\n🎨 Generating {frame_count} frames ({width}×{height}) ...")
    frames_dir.mkdir(parents=True, exist_ok=True)

    for stale_frame in frames_dir.glob("frame-*.png"):
        stale_frame.unlink()

    font    = load_font(FONT_SIZE)
    rgb     = hex_to_rgb(rain_color)
    bg_rgb  = hex_to_rgb(bg_color)
    n_cols  = width  // COL_SPACING
    n_rows  = height // FONT_SIZE

    # Initialise rain columns with varying properties for depth effect
    columns = []
    for _ in range(n_cols):
        # depth_factor controls visual depth (0.3 = far/dim, 1.0 = close/bright)
        depth = random.uniform(0.3, 1.0)
        columns.append({
            "offset": random.randint(0, n_rows),
            "speed":  random.uniform(0.4, 1.2) * depth,
            "length": random.randint(6, 22),
            "depth":  depth,
        })

    for fi in range(frame_count):
        img  = Image.new("RGB", (width, height), color=bg_color)
        draw = ImageDraw.Draw(img)
        t    = fi / frame_count

        for ci, col in enumerate(columns):
            x        = ci * COL_SPACING
            head_row = int(col["offset"] + t * n_rows * col["speed"]) % n_rows
            depth    = col["depth"]

            for trail in range(col["length"]):
                row = (head_row - trail) % n_rows
                y   = row * FONT_SIZE

                if trail == 0:
                    # Head character: bright white-tinted with glow
                    color = blend((255, 255, 255), 0.85 * depth, rgb)
                elif trail == 1:
                    # Second character: near full brightness
                    color = blend(rgb, 0.95 * depth, bg_rgb)
                else:
                    # Trail: exponential falloff for smoother fade
                    alpha = max(0.0, (1.0 - (trail / col["length"]) ** 0.8)) * depth
                    color = blend(rgb, alpha, bg_rgb)

                # Random character flicker: 8% chance to skip drawing
                if trail > 1 and random.random() < 0.08:
                    continue

                char = random.choice(CHARSET)
                draw.text((x, y), char, fill=color, font=font)

        # Quantize to 8-bit palette PNG for drastically smaller file size.
        # The cipher rain uses very few distinct colours (shades of one hue
        # against black), so 256 colours is more than enough.
        # method=0 is MEDIANCUT (compatible with all Pillow versions)
        img_p = img.quantize(colors=256, method=0)
        img_p.save(frames_dir / f"frame-{fi:04d}.png", "PNG", optimize=True)

        # Progress indicator
        if fi % 5 == 0 or fi == frame_count - 1:
            done = int((fi + 1) / frame_count * 25)
            bar  = "█" * done + "░" * (25 - done)
            print(f"   [{bar}] {fi + 1}/{frame_count}", end="\r", flush=True)

    print(f"\n   ✅ {frame_count} frames saved.")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="CipherBoot — Generate all Plymouth theme assets",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 scripts/generate_frames.py --all
  python3 scripts/generate_frames.py --all --variant neon
  python3 scripts/generate_frames.py --all --seed 42
  python3 scripts/generate_frames.py --frames 48 --color "#FF00FF"
        """
    )
    parser.add_argument("--all",     action="store_true", help="Generate frames + background + progress bars")
    parser.add_argument("--variant", default="cipher",    help="Colour preset: cipher | ghost | neon")
    parser.add_argument("--width",   type=int, default=960,  help="Frame width  (default: 960 — half of 1920)")
    parser.add_argument("--height",  type=int, default=540,  help="Frame height (default: 540 — half of 1080)")
    parser.add_argument("--frames",  type=int, default=48,   help="Number of animation frames (default: 48)")
    parser.add_argument("--color",   default=None,        help="Override rain colour e.g. #00FF00")
    parser.add_argument("--bg",      default=None,        help="Override background colour")
    parser.add_argument("--output",  default=None,        help="Override frames output directory")
    parser.add_argument("--assets-output", default=None,  help="Override asset output directory")
    parser.add_argument("--progress-output", default=None, help="Override progress asset output directory")
    parser.add_argument("--seed",    type=int, default=None, help="Random seed for reproducible output")
    args = parser.parse_args()

    # Set random seed if provided (for reproducible generation)
    if args.seed is not None:
        random.seed(args.seed)
        print(f"   🎲 Using random seed: {args.seed}")

    if args.variant not in VARIANTS:
        print(f"❌ Unknown variant '{args.variant}'. Choose: cipher | ghost | neon")
        raise SystemExit(1)

    preset      = VARIANTS[args.variant]
    rain_color  = args.color or preset["rain_color"]
    bg_color    = args.bg    or preset["bg_color"]
    frames_dir  = Path(args.output) if args.output else Path("theme/assets/frames")
    assets_dir  = Path(args.assets_output) if args.assets_output else Path("theme/assets")
    progress_dir = Path(args.progress_output) if args.progress_output else assets_dir / "progress"

    print(f"\n⚡ CipherBoot Asset Generator")
    print(f"   Variant  : {args.variant}")
    print(f"   Rain     : {rain_color}   BG: {bg_color}")
    print(f"   Frames   : {args.frames} @ {args.width}×{args.height}")
    print(f"   Mode     : Optimised PNG8 (palette)")
    print()

    if args.all:
        assets_dir.mkdir(parents=True, exist_ok=True)
        progress_dir.mkdir(parents=True, exist_ok=True)
        make_background(args.width, args.height, bg_color, assets_dir)
        make_progress_bars(preset["bar_bg_color"], preset["bar_fg_color"], progress_dir)

    make_frames(args.width, args.height, args.frames, rain_color, bg_color, frames_dir)

    print()
    print("✅ Done! All assets generated.")
    if args.all:
        print()
        print("   Next steps:")
        print("   sudo ./install.sh")
        print("   sudo ./preview.sh")
        print("   Reboot to see it live!")


if __name__ == "__main__":
    main()
