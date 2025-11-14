#!/bin/bash
# Install rebuild-iso command to PATH
# Run once: sudo ./install-rebuild-command.sh

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} This script must be run as root"
    echo "Usage: sudo ./install-rebuild-command.sh"
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$REPO_ROOT/rebuild-iso.sh"
SYMLINK_PATH="/usr/local/bin/rebuild-iso"

echo -e "${BLUE}Installing rebuild-iso command...${NC}"
echo ""

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error:${NC} rebuild-iso.sh not found at $SCRIPT_PATH"
    exit 1
fi

# Make sure script is executable
chmod +x "$SCRIPT_PATH"

# Create symlink
if [ -L "$SYMLINK_PATH" ] || [ -f "$SYMLINK_PATH" ]; then
    echo "Removing existing command..."
    rm -f "$SYMLINK_PATH"
fi

ln -s "$SCRIPT_PATH" "$SYMLINK_PATH"

echo -e "${GREEN}✓ Command installed successfully!${NC}"
echo ""
echo "You can now rebuild the ISO from anywhere with:"
echo -e "  ${GREEN}sudo rebuild-iso${NC}         (normal build, 20-30 min)"
echo -e "  ${GREEN}sudo rebuild-iso --fast${NC}  (fast build, 5-10 min)"
echo ""
echo "What this command does:"
echo "  1. Pulls latest changes from git"
echo "  2. Cleans old build artifacts (unless --fast)"
echo "  3. Builds the ISO"
echo ""
echo "Fast mode uses:"
echo "  • Cached base system (no debootstrap)"
echo "  • gzip compression (faster than xz)"
echo "  • Perfect for testing changes quickly"
echo ""
