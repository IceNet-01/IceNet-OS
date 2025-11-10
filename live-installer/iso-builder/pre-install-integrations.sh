#!/bin/bash
# Pre-install IceNet integrations into ISO
# This script runs during ISO build to install integrations that will be
# available in the live system and installed OS, but disabled by default

set -e

CHROOT_DIR="$1"
INTEGRATIONS_DIR="$2"

if [ -z "$CHROOT_DIR" ] || [ -z "$INTEGRATIONS_DIR" ]; then
    echo "Usage: $0 <chroot_dir> <integrations_dir>"
    exit 1
fi

log() {
    echo "[PRE-INSTALL] $*"
}

log "Pre-installing IceNet integrations into $CHROOT_DIR"

# Install Python dependencies for GUI applications
log "Installing Python dependencies..."
chroot "$CHROOT_DIR" apt-get install -y \
    python3 \
    python3-gi \
    gir1.2-gtk-3.0 \
    policykit-1 \
    gksu

# 1. Install Thermal Management System
log "Installing Thermal Management System..."
mkdir -p "$CHROOT_DIR/opt/icenet-thermal"

# Create thermal management script
cat > "$CHROOT_DIR/opt/icenet-thermal/thermal-manager.sh" <<'EOF'
#!/bin/bash
# IceNet Thermal Management System
# Keeps hardware warm in cold environments

TEMP_THRESHOLD=10  # Celsius
CHECK_INTERVAL=60  # seconds

while true; do
    # Get CPU temperature
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp_c=$((temp / 1000))

        if [ $temp_c -lt $TEMP_THRESHOLD ]; then
            echo "[$(date)] Temperature low ($temp_c°C), activating heating..."
            # Stress CPU to generate heat
            for i in {1..4}; do
                dd if=/dev/zero of=/dev/null &
            done
            sleep 30
            killall dd 2>/dev/null || true
        fi
    fi

    sleep $CHECK_INTERVAL
done
EOF

chmod +x "$CHROOT_DIR/opt/icenet-thermal/thermal-manager.sh"

# Create systemd service
cat > "$CHROOT_DIR/etc/systemd/system/icenet-thermal.service" <<EOF
[Unit]
Description=IceNet Thermal Management
After=network.target

[Service]
Type=simple
ExecStart=/opt/icenet-thermal/thermal-manager.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

log "✓ Thermal Management System installed (disabled)"

# 2. Install Meshtastic Bridge (Headless)
log "Installing Meshtastic Bridge (Headless)..."

# Install meshtastic Python package
chroot "$CHROOT_DIR" pip3 install --break-system-packages meshtastic 2>/dev/null || \
chroot "$CHROOT_DIR" pip3 install meshtastic

mkdir -p "$CHROOT_DIR/opt/meshtastic-bridge"

# Create bridge script
cat > "$CHROOT_DIR/opt/meshtastic-bridge/bridge.py" <<'EOFPYTHON'
#!/usr/bin/env python3
"""
Meshtastic Bridge - Headless Service
Bridges Meshtastic radios with network services
"""

import meshtastic
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    logger.info("Starting Meshtastic Bridge...")

    try:
        # Connect to Meshtastic device
        interface = meshtastic.serial_interface.SerialInterface()

        logger.info("Connected to Meshtastic device")
        logger.info(f"Node info: {interface.getMyNodeInfo()}")

        # Keep running
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        logger.info("Shutting down...")
    except Exception as e:
        logger.error(f"Error: {e}")
        raise

if __name__ == "__main__":
    main()
EOFPYTHON

chmod +x "$CHROOT_DIR/opt/meshtastic-bridge/bridge.py"

# Create systemd service
cat > "$CHROOT_DIR/etc/systemd/system/meshtastic-bridge.service" <<EOF
[Unit]
Description=Meshtastic Bridge (Headless)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/meshtastic-bridge/bridge.py
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

log "✓ Meshtastic Bridge installed (disabled)"

# 3. Install Mesh Bridge GUI
log "Installing Mesh Bridge GUI..."

mkdir -p "$CHROOT_DIR/opt/mesh-bridge-gui"

# Create GUI application
cat > "$CHROOT_DIR/opt/mesh-bridge-gui/mesh-bridge-gui.py" <<'EOFPYTHON'
#!/usr/bin/env python3
"""
Mesh Bridge GUI
Visual interface for configuring and monitoring mesh bridge
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

class MeshBridgeGUI(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Mesh Bridge Configuration")
        self.set_default_size(700, 500)
        self.set_position(Gtk.WindowPosition.CENTER)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_margin_start(20)
        box.set_margin_end(20)
        box.set_margin_top(20)
        box.set_margin_bottom(20)
        self.add(box)

        # Header
        header = Gtk.Label()
        header.set_markup("<span size='x-large' weight='bold'>Mesh Bridge Configuration</span>")
        box.pack_start(header, False, False, 0)

        # Placeholder content
        content = Gtk.Label()
        content.set_markup(
            "<span size='large'>Configure your Meshtastic mesh network bridge</span>\n\n"
            "This interface allows you to:\n"
            "• Monitor connected radios\n"
            "• Configure bridge settings\n"
            "• View message traffic\n"
            "• Manage network topology"
        )
        box.pack_start(content, True, True, 0)

def main():
    win = MeshBridgeGUI()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()
EOFPYTHON

chmod +x "$CHROOT_DIR/opt/mesh-bridge-gui/mesh-bridge-gui.py"

# Create desktop entry
mkdir -p "$CHROOT_DIR/usr/share/applications"
cat > "$CHROOT_DIR/usr/share/applications/mesh-bridge-gui.desktop" <<EOF
[Desktop Entry]
Name=Mesh Bridge GUI
Comment=Visual interface for mesh bridge configuration
Exec=/opt/mesh-bridge-gui/mesh-bridge-gui.py
Icon=network-wireless
Terminal=false
Type=Application
Categories=Network;
EOF

# Create systemd service (for auto-start option)
cat > "$CHROOT_DIR/etc/systemd/system/mesh-bridge-gui.service" <<EOF
[Unit]
Description=Mesh Bridge GUI
After=graphical.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/opt/mesh-bridge-gui/mesh-bridge-gui.py
Restart=on-failure

[Install]
WantedBy=graphical.target
EOF

log "✓ Mesh Bridge GUI installed (disabled)"

# 4. Install Service Manager
log "Installing IceNet Service Manager..."

# Copy service manager files from integrations
cp "$INTEGRATIONS_DIR/service-manager/icenet-service-manager.py" \
   "$CHROOT_DIR/usr/local/bin/icenet-service-manager"
chmod +x "$CHROOT_DIR/usr/local/bin/icenet-service-manager"

cp "$INTEGRATIONS_DIR/service-manager/icenet-services" \
   "$CHROOT_DIR/usr/local/bin/icenet-services"
chmod +x "$CHROOT_DIR/usr/local/bin/icenet-services"

cp "$INTEGRATIONS_DIR/service-manager/icenet-service-manager.desktop" \
   "$CHROOT_DIR/usr/share/applications/"

log "✓ Service Manager installed"

# Ensure all services are disabled by default
log "Ensuring all services are disabled by default..."
chroot "$CHROOT_DIR" systemctl disable icenet-thermal.service 2>/dev/null || true
chroot "$CHROOT_DIR" systemctl disable meshtastic-bridge.service 2>/dev/null || true
chroot "$CHROOT_DIR" systemctl disable mesh-bridge-gui.service 2>/dev/null || true

log "All integrations pre-installed and disabled by default"
log "Users can enable them via: icenet-service-manager (GUI) or icenet-services (CLI)"
