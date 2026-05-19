#!/usr/bin/env bash
# validate.sh - Lightweight repository checks for CipherBoot.

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Checking shell syntax..."
bash -n install.sh
bash -n uninstall.sh
bash -n preview.sh
bash -n scripts/detect_distro.sh

echo "Checking Python syntax..."
python3 -m py_compile scripts/generate_frames.py scripts/generate_preview.py

echo "Checking required theme descriptors..."
test -f theme/CipherBoot.plymouth
test -f theme/CipherBoot-ghost.plymouth
test -f theme/CipherBoot-neon.plymouth
test -f theme/CipherBoot.script

echo "Checking generated asset set..."
frame_count="$(find theme/assets/frames -maxdepth 1 -name 'frame-*.png' 2>/dev/null | wc -l)"
if [ "$frame_count" -ne 48 ]; then
    echo "Expected 48 animation frames, found $frame_count."
    echo "Run: python3 scripts/generate_frames.py --all"
    exit 1
fi

for i in $(seq 0 47); do
    frame_path="theme/assets/frames/frame-$(printf "%04d" "$i").png"
    if [ ! -f "$frame_path" ]; then
        echo "Missing animation frame: $frame_path"
        exit 1
    fi
done

test -f theme/assets/background.png
test -f theme/assets/progress/progress_bar_bg.png
test -f theme/assets/progress/progress_bar_fg.png

echo "All checks passed."
