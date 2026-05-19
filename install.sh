#!/usr/bin/env bash
# install.sh — CipherBoot Plymouth Theme Installer
# Author: Atharva Jadhav
# License: Apache-2.0
#
# Supports: Ubuntu, Pop!_OS, Zorin OS, Linux Mint, elementary OS,
#           Arch Linux, EndeavourOS, Manjaro, Garuda, CachyOS
#
# Usage:
#   sudo ./install.sh                     # Install default (cipher) variant
#   sudo ./install.sh --variant ghost     # Install ghost variant
#   sudo ./install.sh --variant neon      # Install neon variant
#   sudo ./install.sh --no-grub           # Skip GRUB configuration

set -e   # Exit immediately on any error

# ─── Colour Codes ─────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Constants ────────────────────────────────────────────────────────────────
THEME_NAME="CipherBoot"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
EXPECTED_FRAME_COUNT=48
VARIANT="cipher"
CONFIGURE_GRUB="yes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ASSETS_DIR="${SCRIPT_DIR}/theme/assets"
TMP_ASSETS_DIR=""

cleanup() {
    if [ -n "$TMP_ASSETS_DIR" ] && [ -d "$TMP_ASSETS_DIR" ]; then
        rm -rf "$TMP_ASSETS_DIR"
    fi
}
trap cleanup EXIT

# ─── Parse Arguments ──────────────────────────────────────────────────────────
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --variant)
            VARIANT="$2"
            shift
            ;;
        --no-grub)
            CONFIGURE_GRUB="no"
            ;;
        --help|-h)
            echo "Usage: sudo ./install.sh [--variant cipher|ghost|neon] [--no-grub]"
            echo ""
            echo "Options:"
            echo "  --variant    Choose colour variant: cipher (default), ghost, neon"
            echo "  --no-grub    Skip GRUB configuration (if you manage GRUB manually)"
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

# Validate variant
if [[ "$VARIANT" != "cipher" && "$VARIANT" != "ghost" && "$VARIANT" != "neon" ]]; then
    echo -e "${RED}❌ Invalid variant: '${VARIANT}'${RESET}"
    echo "   Valid options: cipher | ghost | neon"
    exit 1
fi

# ─── Root Check ───────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run with sudo.${RESET}"
    echo -e "   Try: ${CYAN}sudo ./install.sh${RESET}"
    exit 1
fi

# ─── Distro Detection ─────────────────────────────────────────────────────────
# shellcheck source=scripts/detect_distro.sh
source "${SCRIPT_DIR}/scripts/detect_distro.sh"
detect_distro

# ─── Banner ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}⚡ CipherBoot Plymouth Theme Installer${RESET}"
echo -e "   Distro  : ${GREEN}${DISTRO_NAME}${RESET}"
echo -e "   Family  : ${GREEN}${DISTRO_FAMILY}${RESET}"
echo -e "   Variant : ${GREEN}${VARIANT}${RESET}"
echo -e "   Target  : ${GREEN}${THEME_DIR}${RESET}"
echo ""

# ─── Check Plymouth is Installed ──────────────────────────────────────────────
if ! command -v plymouthd &>/dev/null; then
    echo -e "${YELLOW}⚠️  Plymouth not found. Installing now...${RESET}"
    if [ "$DISTRO_FAMILY" = "arch" ]; then
        pacman -Sy --noconfirm plymouth || {
            echo -e "${RED}❌ Failed to install Plymouth.${RESET}"
            echo -e "   Install manually: ${CYAN}sudo pacman -S plymouth${RESET}"
            exit 1
        }
    else
        apt-get update -qq
        apt-get install -y plymouth plymouth-themes 2>/dev/null || \
        apt-get install -y plymouth || {
            echo -e "${RED}❌ Failed to install Plymouth.${RESET}"
            echo -e "   Check your internet connection and try:"
            echo -e "   ${CYAN}sudo apt-get install plymouth${RESET}"
            exit 1
        }
    fi
    echo -e "${GREEN}✅ Plymouth installed.${RESET}"
fi

# ─── Prepare Variant Assets ───────────────────────────────────────────────────
if [ "$VARIANT" != "cipher" ]; then
    echo "🎨 Generating ${VARIANT} variant assets for this install..."

    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}❌ python3 is required to generate variant assets.${RESET}"
        exit 1
    fi

    TMP_ASSETS_DIR=$(mktemp -d /tmp/cipherboot-assets.XXXXXX)
    mkdir -p "${TMP_ASSETS_DIR}/frames" "${TMP_ASSETS_DIR}/progress"

    python3 "${SCRIPT_DIR}/scripts/generate_frames.py" \
        --all \
        --variant "$VARIANT" \
        --output "${TMP_ASSETS_DIR}/frames" \
        --assets-output "$TMP_ASSETS_DIR" \
        --progress-output "${TMP_ASSETS_DIR}/progress" || {
            echo -e "${RED}❌ Failed to generate ${VARIANT} variant assets.${RESET}"
            echo -e "   Install Pillow and try again: ${CYAN}python3 -m pip install pillow${RESET}"
            exit 1
        }

    SOURCE_ASSETS_DIR="$TMP_ASSETS_DIR"
fi

# ─── Check Frame Assets Exist ─────────────────────────────────────────────────
FRAMES_DIR="${SOURCE_ASSETS_DIR}/frames"
FRAME_COUNT=$(find "$FRAMES_DIR" -name "frame-*.png" 2>/dev/null | wc -l)

if [ "$FRAME_COUNT" -lt "$EXPECTED_FRAME_COUNT" ]; then
    echo -e "${RED}❌ Not enough animation frames found in theme/assets/frames/${RESET}"
    echo ""
    echo -e "   CipherBoot needs ${EXPECTED_FRAME_COUNT} contiguous animation frames. Run:"
    echo -e "   ${CYAN}pip install pillow${RESET}"
    echo -e "   ${CYAN}python3 scripts/generate_frames.py --all${RESET}"
    echo ""
    exit 1
fi

for i in $(seq 0 $((EXPECTED_FRAME_COUNT - 1))); do
    frame_path="${FRAMES_DIR}/frame-$(printf "%04d" "$i").png"
    if [ ! -f "$frame_path" ]; then
        echo -e "${RED}❌ Missing animation frame: ${frame_path}${RESET}"
        echo -e "   Regenerate assets with: ${CYAN}python3 scripts/generate_frames.py --all${RESET}"
        exit 1
    fi
done

echo -e "🎞️  Found ${FRAME_COUNT} animation frames."

# ─── Create Theme Directory ───────────────────────────────────────────────────
echo "📁 Creating theme directory..."
mkdir -p "${THEME_DIR}/assets/frames"
mkdir -p "${THEME_DIR}/assets/progress"

# ─── Copy Theme Files ─────────────────────────────────────────────────────────
echo "📋 Copying theme files..."

# Script
cp "${SCRIPT_DIR}/theme/CipherBoot.script" "${THEME_DIR}/" || {
    echo -e "${RED}❌ Failed to copy CipherBoot.script${RESET}"; exit 1
}

# Plymouth descriptor — select correct variant file
if [ "$VARIANT" = "cipher" ]; then
    cp "${SCRIPT_DIR}/theme/CipherBoot.plymouth" "${THEME_DIR}/${THEME_NAME}.plymouth"
else
    cp "${SCRIPT_DIR}/theme/CipherBoot-${VARIANT}.plymouth" "${THEME_DIR}/${THEME_NAME}.plymouth" || {
        echo -e "${RED}❌ Variant file not found: theme/CipherBoot-${VARIANT}.plymouth${RESET}"; exit 1
    }
fi

# Assets
cp "${SOURCE_ASSETS_DIR}/background.png"   "${THEME_DIR}/assets/" || {
    echo -e "${RED}❌ background.png not found in theme/assets/${RESET}"; exit 1
}
# Clean old frames first (prevents stale frames when count changes)
rm -f "${THEME_DIR}/assets/frames/"*.png 2>/dev/null || true
cp "${SOURCE_ASSETS_DIR}/frames"/*.png      "${THEME_DIR}/assets/frames/" || {
    echo -e "${RED}❌ Failed to copy animation frames.${RESET}"; exit 1
}
cp "${SOURCE_ASSETS_DIR}/progress"/*.png    "${THEME_DIR}/assets/progress/" || {
    echo -e "${RED}❌ Failed to copy progress bar assets.${RESET}"; exit 1
}

echo -e "   All files copied."

# ─── Register Theme with Plymouth ─────────────────────────────────────────────
echo "🎨 Registering CipherBoot as default Plymouth theme..."

PLYMOUTH_FILE="${THEME_DIR}/${THEME_NAME}.plymouth"

if command -v plymouth-set-default-theme &>/dev/null; then
    # Method 1: plymouth-set-default-theme (Arch Linux, some Ubuntu flavours)
    plymouth-set-default-theme "${THEME_NAME}" || {
        echo -e "${RED}❌ Failed to set default theme via plymouth-set-default-theme.${RESET}"
        exit 1
    }
    echo -e "   Registered via plymouth-set-default-theme."
elif command -v update-alternatives &>/dev/null; then
    # Method 2: update-alternatives (Ubuntu 22.04+, Zorin OS 17+, and derivatives)
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
        default.plymouth "${PLYMOUTH_FILE}" 200 || {
        echo -e "${RED}❌ Failed to register theme with update-alternatives.${RESET}"
        exit 1
    }

    update-alternatives --set default.plymouth "${PLYMOUTH_FILE}" || {
        echo -e "${RED}❌ Failed to set CipherBoot as default theme.${RESET}"
        exit 1
    }

    echo -e "   Registered via update-alternatives (priority 200)."
else
    echo -e "${YELLOW}⚠️  No theme registration tool found. Theme files copied but not activated.${RESET}"
    echo -e "   You may need to activate the theme manually."
fi

# ─── Create plymouthd.conf ────────────────────────────────────────────────────
echo "📝 Writing /etc/plymouth/plymouthd.conf..."
mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf << EOF
[Daemon]
Theme=${THEME_NAME}
ShowDelay=0
DeviceTimeout=8
EOF
echo -e "   Theme set in plymouthd.conf."

# ─── GRUB Configuration (Smoother Boot Handoff) ───────────────────────────────
# Configures GRUB to pass the framebuffer to the kernel and reduce the black
# screen gap between GRUB menu and Plymouth splash.
#
# IMPORTANT: This only ADDS settings that are missing. It never removes or
# overwrites existing user customizations.

if [ "$CONFIGURE_GRUB" = "yes" ] && [ -f /etc/default/grub ]; then
    echo "🔧 Configuring GRUB for smoother boot handoff..."

    # Create a backup (only if one doesn't already exist from a previous install)
    if [ ! -f /etc/default/grub.cipherboot.bak ]; then
        cp /etc/default/grub /etc/default/grub.cipherboot.bak
        echo -e "   Backup → /etc/default/grub.cipherboot.bak"
    fi

    GRUB_CHANGED=0

    append_kernel_arg() {
        local arg="$1"
        local label="$2"

        if ! grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
            echo "GRUB_CMDLINE_LINUX_DEFAULT=\"${arg}\"" >> /etc/default/grub
            GRUB_CHANGED=1
            echo -e "   Added '${arg}'${label:+ (${label})}"
            return
        fi

        CURRENT_CMDLINE=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | head -1)
        CURRENT_CMDLINE=${CURRENT_CMDLINE#GRUB_CMDLINE_LINUX_DEFAULT=\"}
        CURRENT_CMDLINE=${CURRENT_CMDLINE%\"}
        case " ${CURRENT_CMDLINE} " in
            *" ${arg} "*) return ;;
        esac

        sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 ${arg}\"/" /etc/default/grub
        GRUB_CHANGED=1
        echo -e "   Added '${arg}'${label:+ (${label})}"
    }

    kernel_arg_prefix_present() {
        local prefix="$1"
        CURRENT_CMDLINE=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | head -1)
        CURRENT_CMDLINE=${CURRENT_CMDLINE#GRUB_CMDLINE_LINUX_DEFAULT=\"}
        CURRENT_CMDLINE=${CURRENT_CMDLINE%\"}
        case " ${CURRENT_CMDLINE} " in
            *" ${prefix}"*) return 0 ;;
            *) return 1 ;;
        esac
    }

    # --- GRUB_GFXMODE ---
    # Only set if currently commented out or missing entirely.
    # If the user has already set it to any value, we respect that.
    if grep -q "^#GRUB_GFXMODE=" /etc/default/grub; then
        # Commented out — uncomment and set to auto (works for all resolutions)
        sed -i 's/^#GRUB_GFXMODE=.*/GRUB_GFXMODE=auto/' /etc/default/grub
        GRUB_CHANGED=1
        echo -e "   Set GRUB_GFXMODE=auto (was commented out)"
    elif ! grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
        # Missing entirely — add it
        echo 'GRUB_GFXMODE=auto' >> /etc/default/grub
        GRUB_CHANGED=1
        echo -e "   Added GRUB_GFXMODE=auto"
    else
        echo -e "   GRUB_GFXMODE already set — keeping your value"
    fi

    # --- GRUB_GFXPAYLOAD_LINUX ---
    # This is the critical setting: tells GRUB to pass its framebuffer to the
    # kernel instead of switching to text mode. "keep" means "use whatever
    # GRUB_GFXMODE resolved to".
    if ! grep -q "^GRUB_GFXPAYLOAD_LINUX=" /etc/default/grub; then
        echo 'GRUB_GFXPAYLOAD_LINUX=keep' >> /etc/default/grub
        GRUB_CHANGED=1
        echo -e "   Added GRUB_GFXPAYLOAD_LINUX=keep"
    else
        echo -e "   GRUB_GFXPAYLOAD_LINUX already set — keeping your value"
    fi

    # --- Ensure quiet splash is present in kernel command line ---
    # "quiet" prevents early boot text from forcing a visible VT repaint before
    # Plymouth owns the display; "splash" asks Plymouth to show the theme.
    append_kernel_arg "quiet" "less text before splash"
    append_kernel_arg "splash" "enable Plymouth splash"

    # --- Early KMS modesetting ---
    # Forces GPU drivers to initialise the framebuffer early in boot.
    # Without this, there's a black screen gap while the kernel loads the
    # DRM driver.  Only adds params that are missing.
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        # Intel integrated GPU — early modesetting
        if lspci 2>/dev/null | grep -qi "VGA.*Intel" || lsmod 2>/dev/null | grep -q "^i915"; then
            append_kernel_arg "i915.modeset=1" "Intel early KMS"
        fi

        # NVIDIA discrete GPU — early modesetting
        if lspci 2>/dev/null | grep -qi "VGA.*NVIDIA\|3D.*NVIDIA" || lsmod 2>/dev/null | grep -q "^nvidia_drm"; then
            append_kernel_arg "nvidia-drm.modeset=1" "NVIDIA early KMS"
        fi

        # vt.handoff — reduces VT switch black screen between GRUB and Plymouth.
        if ! kernel_arg_prefix_present "vt.handoff="; then
            append_kernel_arg "vt.handoff=7" "VT handoff"
        fi
    fi

    # --- GRUB_TIMEOUT_STYLE ---
    # Hidden timeout = no visible GRUB menu delay (press Shift/Esc to access)
    if grep -q "^GRUB_TIMEOUT_STYLE=" /etc/default/grub; then
        CURRENT_STYLE=$(grep "^GRUB_TIMEOUT_STYLE=" /etc/default/grub | cut -d= -f2)
        if [ "$CURRENT_STYLE" != "hidden" ]; then
            sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
            GRUB_CHANGED=1
            echo -e "   Set GRUB_TIMEOUT_STYLE=hidden (no visible menu delay)"
        fi
    elif ! grep -q "^GRUB_TIMEOUT_STYLE=" /etc/default/grub; then
        echo 'GRUB_TIMEOUT_STYLE=hidden' >> /etc/default/grub
        GRUB_CHANGED=1
        echo -e "   Added GRUB_TIMEOUT_STYLE=hidden"
    fi

    # Update GRUB config if changes were made
    if [ "$GRUB_CHANGED" -eq 1 ]; then
        if command -v update-grub &>/dev/null; then
            update-grub 2>/dev/null
            echo -e "   ${GREEN}GRUB updated via update-grub.${RESET}"
        elif command -v grub-mkconfig &>/dev/null; then
            # Arch Linux uses grub-mkconfig directly
            grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
            echo -e "   ${GREEN}GRUB updated via grub-mkconfig.${RESET}"
        else
            echo -e "${YELLOW}   ⚠️  No GRUB updater found. Run manually:${RESET}"
            echo -e "   ${CYAN}sudo grub-mkconfig -o /boot/grub/grub.cfg${RESET}"
        fi
    else
        echo -e "   No GRUB changes needed — your config is already optimal."
    fi
elif [ "$CONFIGURE_GRUB" = "no" ]; then
    echo "⏭️  Skipping GRUB configuration (--no-grub flag)."
fi

# ─── DRM Modules in Initramfs ─────────────────────────────────────────────────
# To prevent black screens, the initramfs needs the GPU drivers loaded early.

if [ "$DISTRO_FAMILY" = "ubuntu" ]; then
    echo "🔧 Checking initramfs DRM modules for early KMS..."
    MODULES_FILE="/etc/initramfs-tools/modules"
    MODULES_CHANGED=0

    if [ -f "$MODULES_FILE" ]; then
        # Base DRM module — required for ALL GPU types
        if ! grep -q "^drm$" "$MODULES_FILE"; then
            echo "drm" >> "$MODULES_FILE"
            MODULES_CHANGED=1
            echo -e "   Added drm to initramfs modules"
        fi

        if lspci 2>/dev/null | grep -qi "VGA.*Intel" || lsmod 2>/dev/null | grep -q "^i915"; then
            if ! grep -q "^i915" "$MODULES_FILE"; then
                echo "i915" >> "$MODULES_FILE"
                MODULES_CHANGED=1
                echo -e "   Added i915 to initramfs modules"
            fi
        fi

        if lspci 2>/dev/null | grep -qi "VGA.*NVIDIA\|3D.*NVIDIA" || lsmod 2>/dev/null | grep -q "^nvidia"; then
            if ! grep -q "^nvidia" "$MODULES_FILE"; then
                echo "nvidia" >> "$MODULES_FILE"
                echo "nvidia_modeset" >> "$MODULES_FILE"
                echo "nvidia_uvm" >> "$MODULES_FILE"
                echo "nvidia_drm" >> "$MODULES_FILE"
                MODULES_CHANGED=1
                echo -e "   Added nvidia DRM modules to initramfs"
            fi
        fi
    fi

    # Ensure FRAMEBUFFER=y is set for Plymouth splash
    SPLASH_CONF="/etc/initramfs-tools/conf.d/splash"
    if [ ! -f "$SPLASH_CONF" ] || ! grep -q "FRAMEBUFFER=y" "$SPLASH_CONF"; then
        echo "FRAMEBUFFER=y" > "$SPLASH_CONF"
        MODULES_CHANGED=1
        echo -e "   Set FRAMEBUFFER=y in initramfs splash config"
    fi
fi

# ─── Update initramfs / mkinitcpio ────────────────────────────────────────────
echo "🔄 Rebuilding initial ramdisk (this may take a moment)..."

if [ "$DISTRO_FAMILY" = "arch" ]; then
    # Arch-based: ensure plymouth is in mkinitcpio HOOKS
    if [ -f /etc/mkinitcpio.conf ]; then
        if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
            echo -e "   Adding 'plymouth' hook to mkinitcpio.conf..."
            # Insert 'plymouth' after 'base' in HOOKS array, preserving user's other hooks
            sed -i 's/\(HOOKS=.*\)\(base\)/\1\2 plymouth/' /etc/mkinitcpio.conf
            echo -e "   ${GREEN}Plymouth hook added.${RESET}"
        fi
    fi
    mkinitcpio -P || {
        echo -e "${RED}❌ mkinitcpio failed.${RESET}"
        echo "   Try running manually: sudo mkinitcpio -P"
        exit 1
    }
else
    # Debian/Ubuntu-based: update-initramfs
    update-initramfs -u || {
        echo -e "${RED}❌ update-initramfs failed.${RESET}"
        echo "   Try running manually: sudo update-initramfs -u"
        exit 1
    }
fi

# ─── Success ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✅ CipherBoot (${VARIANT} variant) installed successfully!${RESET}"
echo ""
echo -e "   → ${BOLD}Reboot${RESET} to see your new boot screen."
echo -e "   → Preview without rebooting: ${CYAN}sudo ./preview.sh${RESET}"
echo -e "   → Switch variant:            ${CYAN}sudo ./install.sh --variant ghost${RESET}"
echo -e "   → Uninstall:                 ${CYAN}sudo ./uninstall.sh${RESET}"
echo ""
echo -e "   ${CYAN}https://github.com/Atharva013/CipherBoot-Plymouth${RESET}"
echo ""
