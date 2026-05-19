#!/usr/bin/env bash
# detect_distro.sh — Distro detection utility for CipherBoot
# Source this file from install.sh / uninstall.sh — do not run directly
# Usage: source scripts/detect_distro.sh && detect_distro

detect_distro() {
    if [ ! -f /etc/os-release ]; then
        echo "❌ /etc/os-release not found. Cannot detect distribution." >&2
        exit 1
    fi

    # shellcheck source=/dev/null
    . /etc/os-release

    case "$ID" in
        zorin)
            DISTRO_NAME="Zorin OS"
            DISTRO_FAMILY="ubuntu"
            ;;
        ubuntu)
            DISTRO_NAME="Ubuntu"
            DISTRO_FAMILY="ubuntu"
            ;;
        pop)
            DISTRO_NAME="Pop!_OS"
            DISTRO_FAMILY="ubuntu"
            ;;
        linuxmint)
            DISTRO_NAME="Linux Mint"
            DISTRO_FAMILY="ubuntu"
            ;;
        elementary)
            DISTRO_NAME="elementary OS"
            DISTRO_FAMILY="ubuntu"
            ;;
        arch)
            DISTRO_NAME="Arch Linux"
            DISTRO_FAMILY="arch"
            ;;
        endeavouros)
            DISTRO_NAME="EndeavourOS"
            DISTRO_FAMILY="arch"
            ;;
        manjaro)
            DISTRO_NAME="Manjaro"
            DISTRO_FAMILY="arch"
            ;;
        garuda)
            DISTRO_NAME="Garuda Linux"
            DISTRO_FAMILY="arch"
            ;;
        cachyos)
            DISTRO_NAME="CachyOS"
            DISTRO_FAMILY="arch"
            ;;
        *)
            # Fallback: check if ID_LIKE contains "ubuntu" or "arch"
            if echo "${ID_LIKE:-}" | grep -q "ubuntu"; then
                DISTRO_NAME="${PRETTY_NAME:-Unknown Ubuntu-based distro}"
                DISTRO_FAMILY="ubuntu"
                echo "⚠️  Distro '${ID}' not in CipherBoot's known list but appears Ubuntu-based."
                echo "   Proceeding with installation — CipherBoot should work."
                echo "   If it does, please open a PR to officially add your distro!"
                echo "   https://github.com/Atharva013/CipherBoot-Plymouth"
            elif echo "${ID_LIKE:-}" | grep -q "arch"; then
                DISTRO_NAME="${PRETTY_NAME:-Unknown Arch-based distro}"
                DISTRO_FAMILY="arch"
                echo "⚠️  Distro '${ID}' not in CipherBoot's known list but appears Arch-based."
                echo "   Proceeding with installation — CipherBoot should work."
                echo "   If it does, please open a PR to officially add your distro!"
                echo "   https://github.com/Atharva013/CipherBoot-Plymouth"
            else
                echo "❌ Unsupported distribution: ${PRETTY_NAME:-$ID}" >&2
                echo "" >&2
                echo "   CipherBoot currently supports:" >&2
                echo "     Ubuntu-based: Zorin OS, Ubuntu, Pop!_OS, Linux Mint, elementary OS" >&2
                echo "     Arch-based:   Arch Linux, EndeavourOS, Manjaro, Garuda, CachyOS" >&2
                echo "" >&2
                echo "   If your distro is Ubuntu- or Arch-based, open an issue:" >&2
                echo "   https://github.com/Atharva013/CipherBoot-Plymouth/issues" >&2
                exit 1
            fi
            ;;
    esac

    export DISTRO_NAME
    export DISTRO_FAMILY
}
