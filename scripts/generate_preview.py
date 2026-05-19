#!/usr/bin/env python3
"""
generate_preview.py — Generate an animated GIF preview of the CipherBoot theme
Author: Atharva Jadhav
License: Apache-2.0

Creates preview.gif from the existing animation frames in theme/assets/frames/.
The GIF is sized for GitHub README display (960×540) and includes the progress bar.

Usage:
    python3 scripts/generate_preview.py
    python3 scripts/generate_preview.py --frames-dir theme/assets/frames/ --output preview.gif
"""

import argparse
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ Pillow not installed.")
    print("   Run:  pip install pillow")
    raise SystemExit(1)


def load_font(size: int):
    """Try to load a monospace TrueType font from common system paths."""
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
        "/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf",
        "/usr/share/fonts/truetype/freefont/FreeMono.ttf",
    ]
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except IOError:
            continue
    return ImageFont.load_default()


def generate_preview(frames_dir: Path, progress_dir: Path, output: Path,
                     gif_width: int = 960, gif_height: int = 540,
                     max_gif_frames: int = 48, duration_ms: int = 80):
    """
    Compose a preview GIF from existing theme frames, a progress bar overlay,
    and a brief title card, then save it at a reduced resolution for GitHub.
    """

    # Collect and sort frame files
    frame_files = sorted(frames_dir.glob("frame-*.png"))
    if not frame_files:
        print(f"❌ No frames found in {frames_dir}")
        print("   Run: python3 scripts/generate_frames.py --all")
        raise SystemExit(1)

    total = len(frame_files)
    print(f"📽️  Building preview GIF from {total} frames ...")
    print(f"   Output    : {output}")
    print(f"   GIF size  : {gif_width}×{gif_height}")
    print(f"   GIF frames: {max_gif_frames} (sampled from {total})")
    print()

    # Sample frames evenly if we have more than max_gif_frames
    if total > max_gif_frames:
        indices = [int(i * total / max_gif_frames) for i in range(max_gif_frames)]
    else:
        indices = list(range(total))

    # Load progress bar assets
    bar_bg_path = progress_dir / "progress_bar_bg.png"
    bar_fg_path = progress_dir / "progress_bar_fg.png"
    has_bars = bar_bg_path.exists() and bar_fg_path.exists()

    if has_bars:
        bar_bg_orig = Image.open(bar_bg_path).convert("RGB")
        bar_fg_orig = Image.open(bar_fg_path).convert("RGB")

    font = load_font(14)
    gif_frames = []

    for step, idx in enumerate(indices):
        frame_path = frame_files[idx]
        img = Image.open(frame_path).convert("RGB")

        # Resize to GIF dimensions
        img = img.resize((gif_width, gif_height), Image.LANCZOS)

        # Draw simulated progress bar overlay
        if has_bars:
            progress = step / max(len(indices) - 1, 1)
            bar_w = int(bar_bg_orig.width * gif_width / 1920)
            bar_h = int(bar_bg_orig.height * gif_height / 1080)
            bar_x = (gif_width - bar_w) // 2
            bar_y = gif_height - 30

            # Scale and paste background bar
            bar_bg_scaled = bar_bg_orig.resize((bar_w, bar_h), Image.LANCZOS)
            img.paste(bar_bg_scaled, (bar_x, bar_y))

            # Scale and paste filled portion
            filled_w = max(1, int(bar_w * progress))
            bar_fg_crop = bar_fg_orig.crop((0, 0, int(bar_fg_orig.width * progress) or 1, bar_fg_orig.height))
            bar_fg_scaled = bar_fg_crop.resize((filled_w, bar_h), Image.LANCZOS)
            img.paste(bar_fg_scaled, (bar_x, bar_y))

        # Convert to palette mode for GIF (reduces file size)
        img_p = img.quantize(colors=128, method=0)  # 0 = MEDIANCUT
        gif_frames.append(img_p)

        # Progress indicator
        done = int((step + 1) / len(indices) * 25)
        bar = "█" * done + "░" * (25 - done)
        print(f"   [{bar}] {step + 1}/{len(indices)}", end="\r", flush=True)

    print()

    # Save as animated GIF
    print("   💾 Saving GIF (this may take a moment) ...")
    gif_frames[0].save(
        output,
        save_all=True,
        append_images=gif_frames[1:],
        duration=duration_ms,
        loop=0,
        optimize=True,
    )

    file_size = output.stat().st_size
    size_str = f"{file_size / 1024:.0f} KB" if file_size < 1024 * 1024 else f"{file_size / (1024*1024):.1f} MB"
    print(f"   ✅ Saved: {output} ({size_str})")


def main():
    parser = argparse.ArgumentParser(
        description="Generate an animated GIF preview of the CipherBoot Plymouth theme"
    )
    parser.add_argument("--frames-dir", default="theme/assets/frames",
                        help="Directory containing frame PNGs")
    parser.add_argument("--progress-dir", default="theme/assets/progress",
                        help="Directory containing progress bar PNGs")
    parser.add_argument("--output", default="preview.gif",
                        help="Output GIF file path")
    parser.add_argument("--width", type=int, default=960,
                        help="GIF width in pixels (default: 960)")
    parser.add_argument("--height", type=int, default=540,
                        help="GIF height in pixels (default: 540)")
    parser.add_argument("--gif-frames", type=int, default=48,
                        help="Number of frames in the GIF (default: 48)")
    parser.add_argument("--duration", type=int, default=80,
                        help="Milliseconds per frame (default: 80)")
    args = parser.parse_args()

    if args.width < 1 or args.height < 1:
        print("❌ --width and --height must be positive integers")
        raise SystemExit(1)

    if args.gif_frames < 1:
        print("❌ --gif-frames must be at least 1")
        raise SystemExit(1)

    if args.duration < 1:
        print("❌ --duration must be at least 1")
        raise SystemExit(1)

    generate_preview(
        frames_dir=Path(args.frames_dir),
        progress_dir=Path(args.progress_dir),
        output=Path(args.output),
        gif_width=args.width,
        gif_height=args.height,
        max_gif_frames=args.gif_frames,
        duration_ms=args.duration,
    )


if __name__ == "__main__":
    main()
