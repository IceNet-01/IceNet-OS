#!/bin/bash
# Install IceNet Service Manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing IceNet Service Manager..."

# Install GUI
sudo cp "$SCRIPT_DIR/icenet-service-manager.py" /usr/local/bin/icenet-service-manager
sudo chmod +x /usr/local/bin/icenet-service-manager

# Install CLI
sudo cp "$SCRIPT_DIR/icenet-services" /usr/local/bin/icenet-services
sudo chmod +x /usr/local/bin/icenet-services

# Install desktop entry
sudo mkdir -p /usr/share/applications
sudo cp "$SCRIPT_DIR/icenet-service-manager.desktop" /usr/share/applications/

echo "✓ IceNet Service Manager installed"
echo ""
echo "Usage:"
echo "  GUI: icenet-service-manager"
echo "  CLI: icenet-services list"
