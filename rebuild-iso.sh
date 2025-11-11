#!/bin/bash
# IceNet-OS ISO Rebuild Script
# Quick rebuild: pulls latest changes, cleans build artifacts, and rebuilds ISO
#
# Usage:
#   sudo ./rebuild-iso.sh           # Normal build (best compression, ~20-30 min)
#   sudo ./rebuild-iso.sh --fast    # Fast build (cached + fast compression, ~5-10 min)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BRANCH="claude/icenet-os-creation-011CUzS211c7Rkn4cHT5YHFQ"

# Parse arguments
FAST_MODE=false
if [ "$1" = "--fast" ] || [ "$1" = "-f" ]; then
    FAST_MODE=true
fi

log() {
    echo -e "${BLUE}[REBUILD]${NC} $1"
}

success() {
    echo -e "${GREEN}[REBUILD]${NC} $1"
}

error() {
    echo -e "${RED}[REBUILD]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[REBUILD]${NC} $1"
}

check_cache_status() {
    local cache_dir="/tmp/icenet-iso-build/.cache/base-system"

    if [ ! -d "$cache_dir" ]; then
        return 1
    fi

    # Quick validation - check for essential components
    if [ ! -f "$cache_dir/usr/bin/apt-get" ] || \
       [ ! -f "$cache_dir/usr/sbin/update-initramfs" ] || \
       ! ls "$cache_dir/boot/vmlinuz-"* >/dev/null 2>&1 || \
       ! ls "$cache_dir/boot/initrd.img-"* >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# Get script directory (repo root) - resolve symlinks
SCRIPT_PATH="${BASH_SOURCE[0]}"
# Follow symlinks to get real script location
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
cd "$REPO_ROOT"

log "IceNet-OS ISO Rebuild Script"
log "Repository: $REPO_ROOT"
echo ""

# Check if we need sudo
if [ "$EUID" -ne 0 ]; then
    error "This script must be run with sudo: sudo ./rebuild-iso.sh"
fi

# Step 1: Pull latest changes
log "Pulling latest changes from $BRANCH..."
if git pull origin "$BRANCH"; then
    success "Git pull completed"
else
    error "Git pull failed"
fi

echo ""

# Step 2: Clean build artifacts
if [ "$FAST_MODE" = "false" ]; then
    log "Cleaning old build artifacts..."
    rm -rf /tmp/icenet-iso-build
    rm -rf "$REPO_ROOT/live-installer/iso-builder/output/"*
    success "Build artifacts cleaned"
else
    log "FAST MODE: Keeping /tmp/icenet-iso-build for incremental build"
    rm -rf "$REPO_ROOT/live-installer/iso-builder/output/"*
fi
echo ""

# Step 3: Validate cache if using fast mode
if [ "$FAST_MODE" = "true" ]; then
    log "Checking cache status for fast mode..."
    if check_cache_status; then
        success "✓ Valid cache found - fast mode will work"
    else
        warning "⚠ No valid cache found!"
        warning "Fast mode will automatically fall back to normal build"
        warning "This first run will take 20-30 minutes to create the cache"
        echo ""
        warning "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
        sleep 5
    fi
    echo ""
fi

# Step 4: Build ISO
if [ "$FAST_MODE" = "true" ]; then
    log "Starting FAST ISO build..."
    log "Using: Cached base system + Fast compression"
    log "Estimated time: 5-10 minutes (or 20-30 min if cache missing)"
    echo ""
    cd "$REPO_ROOT/live-installer/iso-builder"
    if FAST_BUILD=true FAST_COMPRESSION=true ./build-iso.sh; then
        BUILD_SUCCESS=true
    else
        BUILD_SUCCESS=false
    fi
else
    log "Starting NORMAL ISO build..."
    log "Using: Fresh debootstrap + Best compression"
    log "Estimated time: 20-30 minutes"
    echo ""
    cd "$REPO_ROOT/live-installer/iso-builder"
    if ./build-iso.sh; then
        BUILD_SUCCESS=true
    else
        BUILD_SUCCESS=false
    fi
fi

if [ "$BUILD_SUCCESS" = "true" ]; then
    echo ""
    success "========================================="
    success "ISO REBUILD COMPLETE!"
    success "========================================="
    echo ""

    # Find the ISO
    ISO_FILE=$(ls -t output/*.iso 2>/dev/null | head -n1)
    if [ -n "$ISO_FILE" ]; then
        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
        success "ISO Location: $ISO_FILE"
        success "ISO Size: $ISO_SIZE"

        if [ "$FAST_MODE" = "true" ]; then
            echo ""
            log "FAST MODE used - ISO may be larger due to gzip compression"
            log "For smaller ISO, run: sudo rebuild-iso (without --fast)"
        else
            # Check if cache was created
            if check_cache_status; then
                echo ""
                success "✓ Cache created successfully!"
                log "Next rebuild can use: sudo rebuild-iso --fast (5-10 minutes)"
            fi
        fi

        echo ""
        log "To test in VM:"
        echo "  qemu-system-x86_64 -m 2G -cdrom $ISO_FILE -boot d"
        echo ""
        log "To write to USB:"
        echo "  sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
        echo ""
        log "For faster rebuilds next time:"
        echo "  sudo rebuild-iso --fast    (5-10 min using cache)"
    fi
else
    error "ISO build failed - check output above for errors"
fi
