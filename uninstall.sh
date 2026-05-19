#!/usr/bin/env bash
# uninstall.sh — CipherBoot Plymouth Theme Uninstaller
# Author: Atharva Jadhav
# License: Apache-2.0
#
# Supports: Ubuntu, Pop!_OS, Zorin OS, Linux Mint, elementary OS,
#           Arch Linux, EndeavourOS, Manjaro, Garuda, CachyOS
#
# Usage: sudo ./uninstall.sh

set -e

# ─── Colour Codes ─────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

THEME_NAME="CipherBoot"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
DEFAULT_THEME="bgrt"   # System default on most Ubuntu-based distros
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Root Check ───────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run with sudo: sudo ./uninstall.sh${RESET}"
    exit 1
fi

# ─── Distro Detection ─────────────────────────────────────────────────────────
# shellcheck source=scripts/detect_distro.sh
source "${SCRIPT_DIR}/scripts/detect_distro.sh"
detect_distro

# ─── Check if Installed ───────────────────────────────────────────────────────
if [ ! -d "$THEME_DIR" ]; then
    echo -e "${YELLOW}⚠️  CipherBoot does not appear to be installed (${THEME_DIR} not found).${RESET}"
    exit 0
fi

echo ""
echo -e "${CYAN}${BOLD}🗑️  CipherBoot Plymouth Theme Uninstaller${RESET}"
echo -e "   Distro: ${GREEN}${DISTRO_NAME}${RESET}"
echo ""

# ─── Restore Default Theme ────────────────────────────────────────────────────
echo "🎨 Restoring system default Plymouth theme..."

PLYMOUTH_FILE="${THEME_DIR}/${THEME_NAME}.plymouth"

if command -v plymouth-set-default-theme &>/dev/null; then
    # Method 1: plymouth-set-default-theme (Arch Linux, some Ubuntu flavours)
    if [ "$DISTRO_FAMILY" = "arch" ]; then
        # Arch doesn't have bgrt by default — try spinner, then text
        if plymouth-set-default-theme spinner 2>/dev/null; then
            echo -e "   Restored to: ${GREEN}spinner${RESET}"
        elif plymouth-set-default-theme text 2>/dev/null; then
            echo -e "   Restored to: ${GREEN}text${RESET}"
        else
            echo -e "${YELLOW}   No fallback theme found — Plymouth will use default.${RESET}"
        fi
    else
        if plymouth-set-default-theme "$DEFAULT_THEME" 2>/dev/null; then
            echo -e "   Restored to: ${GREEN}${DEFAULT_THEME}${RESET}"
        elif plymouth-set-default-theme text 2>/dev/null; then
            echo -e "${YELLOW}   bgrt not found — restored to: text${RESET}"
        else
            echo -e "${RED}❌ Could not restore a default theme.${RESET}"
        fi
    fi
elif command -v update-alternatives &>/dev/null; then
    # Method 2: update-alternatives (Ubuntu 22.04+, Zorin OS 17+)
    update-alternatives --remove default.plymouth "${PLYMOUTH_FILE}" 2>/dev/null || true
    update-alternatives --auto default.plymouth 2>/dev/null || true

    RESTORED=$(update-alternatives --query default.plymouth 2>/dev/null | grep "^Value:" | cut -d' ' -f2)
    if [ -n "$RESTORED" ]; then
        echo -e "   Restored to: ${GREEN}$(basename "$(dirname "$RESTORED")")${RESET}"
    else
        echo -e "   ${YELLOW}System will use its default theme.${RESET}"
    fi
fi

# ─── Remove plymouthd.conf ────────────────────────────────────────────────────
if [ -f /etc/plymouth/plymouthd.conf ]; then
    echo "📝 Removing /etc/plymouth/plymouthd.conf..."
    rm -f /etc/plymouth/plymouthd.conf
fi

# ─── Restore GRUB Configuration ───────────────────────────────────────────────
if [ -f /etc/default/grub.cipherboot.bak ]; then
    echo "🔧 Restoring original GRUB configuration..."
    cp /etc/default/grub.cipherboot.bak /etc/default/grub
    rm -f /etc/default/grub.cipherboot.bak
    echo -e "   Restored from backup."

    # Regenerate GRUB config
    if command -v update-grub &>/dev/null; then
        update-grub 2>/dev/null
        echo -e "   ${GREEN}GRUB config regenerated via update-grub.${RESET}"
    elif command -v grub-mkconfig &>/dev/null; then
        grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
        echo -e "   ${GREEN}GRUB config regenerated via grub-mkconfig.${RESET}"
    fi
else
    echo "   No GRUB backup found — your GRUB config was not modified by CipherBoot."
fi

# ─── Remove Theme Files ───────────────────────────────────────────────────────
echo "🧹 Removing CipherBoot theme files..."
rm -rf "$THEME_DIR"
echo -e "   Removed: ${THEME_DIR}"

# ─── Update initramfs / mkinitcpio ────────────────────────────────────────────
echo "🔄 Rebuilding initial ramdisk..."

if [ "$DISTRO_FAMILY" = "arch" ]; then
    mkinitcpio -P 2>/dev/null || {
        echo -e "${YELLOW}⚠️  mkinitcpio rebuild failed. Run manually: sudo mkinitcpio -P${RESET}"
    }
else
    update-initramfs -u 2>/dev/null || {
        echo -e "${YELLOW}⚠️  update-initramfs failed. Run manually: sudo update-initramfs -u${RESET}"
    }
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✅ CipherBoot uninstalled. System default theme restored.${RESET}"
echo -e "   Reboot to confirm."
echo ""
echo -e "   ${CYAN}https://github.com/Atharva013/CipherBoot-Plymouth${RESET}"
echo ""
