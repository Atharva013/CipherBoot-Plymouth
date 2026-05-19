#!/usr/bin/env bash
# preview.sh — Preview CipherBoot Plymouth Theme Without Rebooting
# Author: Atharva Jadhav
# License: Apache-2.0
#
# Two preview modes:
#   Mode A (default) — Plymouth test window inside your desktop (best effort)
#   Mode B (--simple) — Renders a single frame as PNG and opens it in image viewer
#
# Supports: Ubuntu-based and Arch-based distributions.
#
# Usage:
#   sudo ./preview.sh        ← Full Plymouth window preview (best effort)
#   ./preview.sh --simple    ← Opens frame-0000.png in image viewer (reliable)

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

THEME_NAME="CipherBoot"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
MODE="full"
LOG_FILE="/tmp/cipherboot_preview.log"
PID_FILE="/tmp/cipherboot_preview.pid"

has_plymouth_x11_renderer() {
    find /usr/lib /lib -path '*plymouth*renderers*x11.so' -print -quit 2>/dev/null | grep -q .
}

# ─── Parse Args ───────────────────────────────────────────────────────────────
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --simple) MODE="simple" ;;
        --help|-h)
            echo "Usage: ./preview.sh [--simple]"
            echo "  (no flag)   Full Plymouth window preview (run with sudo)"
            echo "  --simple    Open a frame PNG in your image viewer (sudo not needed)"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${RESET}"
            echo "   Use --help for usage."
            exit 1
            ;;
    esac
    shift
done

# ─── Simple Mode: just open a frame PNG ───────────────────────────────────────
if [ "$MODE" = "simple" ]; then
    FRAME="theme/assets/frames/frame-0000.png"
    if [ ! -f "$FRAME" ]; then
        echo -e "${RED}❌ Frame not found: ${FRAME}${RESET}"
        echo "   Run: python3 scripts/generate_frames.py --all"
        exit 1
    fi
    echo -e "${CYAN}🖼️  Opening frame preview...${RESET}"
    # Try common image viewers (covers Ubuntu + Arch desktop environments)
    for viewer in eog feh gwenview sxiv imv display xdg-open; do
        if command -v "$viewer" &>/dev/null; then
            if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
                sudo -u "$SUDO_USER" "$viewer" "$FRAME" &
            else
                "$viewer" "$FRAME" &
            fi
            echo -e "${GREEN}✅ Opened with: ${viewer}${RESET}"
            echo "   This is frame-0000 of 48. All frames are in theme/assets/frames/"
            exit 0
        fi
    done
    echo -e "${YELLOW}⚠️  No image viewer found. Open this file manually:${RESET}"
    echo "   $(pwd)/${FRAME}"
    exit 0
fi

# ─── Root Check ───────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Full Plymouth preview needs sudo: sudo ./preview.sh${RESET}"
    echo -e "   For the reliable image preview, run: ${CYAN}./preview.sh --simple${RESET}"
    exit 1
fi

# ─── Full Plymouth Preview Mode ───────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}👁️  CipherBoot Plymouth Preview${RESET}"
echo ""

# Install check
if [ ! -d "$THEME_DIR" ]; then
    echo -e "${RED}❌ Theme not installed.${RESET}"
    echo -e "   Run: ${CYAN}sudo ./install.sh${RESET}  then try preview again."
    exit 1
fi

# Display check — support both X11 and Wayland
if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
    echo -e "${YELLOW}⚠️  No display server detected (\$DISPLAY / \$WAYLAND_DISPLAY not set).${RESET}"
    echo "   Try the simple mode instead: ./preview.sh --simple"
    exit 1
fi

if ! has_plymouth_x11_renderer; then
    echo -e "${YELLOW}⚠️  Plymouth X11 renderer not found.${RESET}"
    echo "   Full desktop preview usually needs the plymouth-x11 package."
    echo -e "   Install it on Ubuntu/Zorin: ${CYAN}sudo apt install plymouth-x11${RESET}"
    echo -e "   Reliable fallback: ${CYAN}./preview.sh --simple${RESET}"
    exit 1
fi

PREVIEW_TTY="$(tty 2>/dev/null || true)"
if [ -z "$PREVIEW_TTY" ] || [ "$PREVIEW_TTY" = "not a tty" ]; then
    PREVIEW_TTY="/dev/tty7"
fi

if plymouth --ping 2>/dev/null; then
    plymouth quit 2>/dev/null || true
    sleep 0.5
fi

echo -e "   Starting Plymouth daemon in test mode..."

PLYD_PID=""
cleanup() {
    plymouth quit --retain-splash 2>/dev/null || true
    sleep 0.3
    [ -n "$PLYD_PID" ] && kill "$PLYD_PID" 2>/dev/null || true
    wait "$PLYD_PID" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo -e "\n${GREEN}✅ Preview ended.${RESET}"
}
trap cleanup EXIT INT TERM

# Start Plymouth daemon
rm -f "$LOG_FILE" "$PID_FILE"
plymouthd \
    --no-daemon \
    --debug \
    --debug-file="$LOG_FILE" \
    --mode=boot \
    --kernel-command-line="quiet splash" \
    --tty="$PREVIEW_TTY" \
    --pid-file="$PID_FILE" &
PLYD_PID=$!

for _ in $(seq 1 20); do
    if plymouth --ping 2>/dev/null; then
        break
    fi
    sleep 0.1
done

if ! plymouth --ping 2>/dev/null; then
    echo -e "${RED}❌ Plymouth daemon did not start.${RESET}"
    echo "   Debug log: $LOG_FILE"
    echo -e "   Reliable fallback: ${CYAN}./preview.sh --simple${RESET}"
    exit 1
fi

plymouth change-mode --boot-up 2>/dev/null || true

# Show splash
plymouth show-splash 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Plymouth window may not have appeared.${RESET}"
    echo "   Check $LOG_FILE for errors."
    echo ""
    echo "   If it didn't show, try the simple mode:"
    echo -e "   ${CYAN}./preview.sh --simple${RESET}"
    exit 1
}

echo -e "   ${GREEN}Simulating boot progress...${RESET}"

# Simulate boot progress using Plymouth's update command
for i in $(seq 0 4 100); do
    progress_value="$(awk "BEGIN { printf \"%.2f\", $i / 100 }")"
    plymouth system-update --progress="$progress_value" 2>/dev/null || \
        plymouth update --status="$i" 2>/dev/null || true
    done_blocks=$((i / 4))
    bar=$(printf "█%.0s" $(seq 1 "$done_blocks" 2>/dev/null))
    printf "   Progress: %-26s %3d%%\r" "$bar" "$i"
    sleep 0.15
done

echo ""
sleep 2
# cleanup() fires automatically on EXIT
