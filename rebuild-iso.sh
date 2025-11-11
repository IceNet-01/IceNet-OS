#!/bin/bash
# IceNet-OS ISO Rebuild Script
# Quick rebuild: pulls latest changes, cleans build artifacts, and rebuilds ISO

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BRANCH="claude/icenet-os-creation-011CUzS211c7Rkn4cHT5YHFQ"

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
log "Cleaning old build artifacts..."
rm -rf /tmp/icenet-iso-build
rm -rf "$REPO_ROOT/live-installer/iso-builder/output/"*

success "Build artifacts cleaned"
echo ""

# Step 3: Build ISO
log "Starting ISO build..."
log "This will take 15-30 minutes depending on your system"
echo ""

cd "$REPO_ROOT/live-installer/iso-builder"

if ./build-iso.sh; then
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
        echo ""
        log "To test in VM:"
        echo "  qemu-system-x86_64 -m 2G -cdrom $ISO_FILE -boot d"
        echo ""
        log "To write to USB:"
        echo "  sudo dd if=$ISO_FILE of=/dev/sdX bs=4M status=progress"
    fi
else
    error "ISO build failed - check output above for errors"
fi
