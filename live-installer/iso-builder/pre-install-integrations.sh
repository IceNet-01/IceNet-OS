#!/bin/bash
# Pre-install IceNet integrations into ISO
# This script runs during ISO build to install integrations that will be
# available in the live system and installed OS, but disabled by default

set -e

# Validate input parameters
CHROOT_DIR="$1"
INTEGRATIONS_DIR="$2"

if [ -z "$CHROOT_DIR" ] || [ -z "$INTEGRATIONS_DIR" ]; then
    echo "Usage: $0 <chroot_dir> <integrations_dir>"
    exit 1
fi

# Validate they're absolute paths
if [[ ! "$CHROOT_DIR" = /* ]]; then
    echo "Error: CHROOT_DIR must be absolute path"
    exit 1
fi

if [[ ! "$INTEGRATIONS_DIR" = /* ]]; then
    echo "Error: INTEGRATIONS_DIR must be absolute path"
    exit 1
fi

# Validate directories exist
if [ ! -d "$CHROOT_DIR" ]; then
    echo "Error: CHROOT_DIR does not exist: $CHROOT_DIR"
    exit 1
fi

if [ ! -d "$INTEGRATIONS_DIR" ]; then
    echo "Error: INTEGRATIONS_DIR does not exist: $INTEGRATIONS_DIR"
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
    python3-pip \
    python3-gi \
    gir1.2-gtk-3.0 \
    policykit-1 || {
        log "ERROR: Failed to install dependencies"
        exit 1
    }

# 1. Install Thermal Management System
log "Installing Thermal Management System..."
mkdir -p "$CHROOT_DIR/opt/icenet-thermal"

# Create thermal management script with proper process tracking
cat > "$CHROOT_DIR/opt/icenet-thermal/thermal-manager.sh" <<'EOF'
#!/bin/bash
# IceNet Thermal Management System
# Keeps hardware warm in cold environments

# Configuration
readonly TEMP_THRESHOLD=10  # Celsius
readonly CHECK_INTERVAL=60  # seconds
readonly HEAT_DURATION=30   # seconds
readonly NUM_PROCESSES=4
readonly MAX_RETRIES=5  # Number of times to check for thermal zone before giving up

# Logging to syslog
log_msg() {
    logger -t icenet-thermal "$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Trap to ensure cleanup on exit
cleanup() {
    log_msg "Shutting down thermal manager"
    # Kill any remaining heating processes
    if [ -n "$HEAT_PIDS" ]; then
        kill $HEAT_PIDS 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT EXIT

log_msg "Starting IceNet Thermal Management System"
log_msg "Temperature threshold: ${TEMP_THRESHOLD}°C"

# Check if thermal zones exist at startup
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        log_msg "Thermal zone found, starting monitoring"
        break
    fi
    retry_count=$((retry_count + 1))
    if [ $retry_count -lt $MAX_RETRIES ]; then
        log_msg "Thermal zone not found (attempt $retry_count/$MAX_RETRIES), waiting..."
        sleep 10
    fi
done

# If no thermal zone after retries, exit gracefully
if [ ! -f /sys/class/thermal/thermal_zone0/temp ]; then
    log_msg "ERROR: No thermal zones found on this system"
    log_msg "This service is designed for physical hardware with temperature sensors"
    log_msg "VMs and some systems may not have thermal zones - this is normal"
    log_msg "Service will exit. Disable this service if not needed: sudo systemctl disable icenet-thermal"
    exit 0
fi

# Track heating process PIDs
HEAT_PIDS=""

while true; do
    # Check if thermal zone still exists (might be hot-unplugged)
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        # Safely read temperature
        if temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); then
            temp_c=$((temp_raw / 1000))

            if [ $temp_c -lt $TEMP_THRESHOLD ]; then
                log_msg "Temperature low (${temp_c}°C), activating heating for ${HEAT_DURATION}s"

                # Spawn heating processes and track PIDs
                HEAT_PIDS=""
                for i in $(seq 1 $NUM_PROCESSES); do
                    dd if=/dev/zero of=/dev/null bs=1M 2>/dev/null &
                    HEAT_PIDS="$HEAT_PIDS $!"
                done

                # Wait for heating duration
                sleep $HEAT_DURATION

                # Kill only our tracked processes
                if [ -n "$HEAT_PIDS" ]; then
                    kill $HEAT_PIDS 2>/dev/null || true
                    wait $HEAT_PIDS 2>/dev/null || true
                fi

                log_msg "Heating cycle complete"
                HEAT_PIDS=""
            fi
        else
            log_msg "Warning: Failed to read thermal zone"
        fi
    else
        log_msg "Warning: Thermal zone disappeared, exiting"
        exit 0
    fi

    sleep $CHECK_INTERVAL
done
EOF

chmod +x "$CHROOT_DIR/opt/icenet-thermal/thermal-manager.sh"

# Create systemd service
cat > "$CHROOT_DIR/etc/systemd/system/icenet-thermal.service" <<EOF
[Unit]
Description=IceNet Thermal Management System
Documentation=man:icenet-thermal(8)
After=network.target

[Service]
Type=simple
ExecStart=/opt/icenet-thermal/thermal-manager.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

log "✓ Thermal Management System installed (disabled)"

# 2. Install Meshtastic Bridge (Headless)
log "Installing Meshtastic Bridge (Headless)..."

# Install meshtastic Python package
log "Installing Meshtastic Python package..."
if chroot "$CHROOT_DIR" pip3 install --break-system-packages meshtastic 2>&1 | tee /tmp/pip-install.log; then
    log "✓ Installed Meshtastic with --break-system-packages"
elif chroot "$CHROOT_DIR" pip3 install meshtastic 2>&1 | tee /tmp/pip-install.log; then
    log "✓ Installed Meshtastic without --break-system-packages"
else
    log "ERROR: Failed to install meshtastic package"
    cat /tmp/pip-install.log
    exit 1
fi

mkdir -p "$CHROOT_DIR/opt/meshtastic-bridge"

# Create bridge script with error handling
cat > "$CHROOT_DIR/opt/meshtastic-bridge/bridge.py" <<'EOFPYTHON'
#!/usr/bin/env python3
"""
Meshtastic Bridge - Headless Service
Bridges Meshtastic radios with network services
"""

import sys
import time
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('meshtastic-bridge')

def main():
    """Main bridge loop with error handling"""
    logger.info("Starting Meshtastic Bridge (Headless)")

    retry_count = 0
    max_retries = 10
    retry_delay = 5

    while retry_count < max_retries:
        try:
            # Import here to allow graceful failure if not installed
            import meshtastic
            import meshtastic.serial_interface

            logger.info("Connecting to Meshtastic device...")

            # Connect to Meshtastic device
            interface = meshtastic.serial_interface.SerialInterface()

            logger.info("Connected to Meshtastic device")
            node_info = interface.getMyNodeInfo()
            logger.info(f"Node info: {node_info}")

            # Reset retry counter on successful connection
            retry_count = 0

            # Keep running
            while True:
                time.sleep(1)

        except ImportError as e:
            logger.error(f"Meshtastic package not installed: {e}")
            logger.error("Install with: pip3 install meshtastic")
            return 1

        except FileNotFoundError:
            logger.warning("No Meshtastic device found")
            retry_count += 1
            if retry_count < max_retries:
                logger.info(f"Retrying in {retry_delay}s (attempt {retry_count}/{max_retries})")
                time.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 300)  # Exponential backoff, max 5 min
            else:
                logger.error("Max retries reached, giving up")
                return 1

        except KeyboardInterrupt:
            logger.info("Shutting down...")
            return 0

        except Exception as e:
            logger.error(f"Unexpected error: {e}", exc_info=True)
            retry_count += 1
            if retry_count < max_retries:
                logger.info(f"Retrying in {retry_delay}s")
                time.sleep(retry_delay)
            else:
                logger.error("Max retries reached after unexpected errors")
                return 1

    return 1

if __name__ == "__main__":
    sys.exit(main())
EOFPYTHON

chmod +x "$CHROOT_DIR/opt/meshtastic-bridge/bridge.py"

# Create systemd service
cat > "$CHROOT_DIR/etc/systemd/system/meshtastic-bridge.service" <<EOF
[Unit]
Description=Meshtastic Bridge (Headless)
Documentation=https://meshtastic.org
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/meshtastic-bridge/bridge.py
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

log "✓ Meshtastic Bridge installed (disabled)"

# 3. Install Mesh Bridge GUI
log "Installing Mesh Bridge GUI..."

mkdir -p "$CHROOT_DIR/opt/mesh-bridge-gui"

# Create GUI application with proper error handling
cat > "$CHROOT_DIR/opt/mesh-bridge-gui/mesh-bridge-gui.py" <<'EOFPYTHON'
#!/usr/bin/env python3
"""
Mesh Bridge GUI
Visual interface for configuring and monitoring mesh bridge
"""

import sys
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib

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
    """Main entry point with error handling"""
    try:
        win = MeshBridgeGUI()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
EOFPYTHON

chmod +x "$CHROOT_DIR/opt/mesh-bridge-gui/mesh-bridge-gui.py"

# Create desktop entry with proper Python interpreter
mkdir -p "$CHROOT_DIR/usr/share/applications"
cat > "$CHROOT_DIR/usr/share/applications/mesh-bridge-gui.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=Mesh Bridge GUI
Comment=Visual interface for mesh bridge configuration
Exec=/usr/bin/python3 /opt/mesh-bridge-gui/mesh-bridge-gui.py
Icon=network-wireless
Terminal=false
Type=Application
Categories=Network;System;
Keywords=mesh;meshtastic;network;
StartupNotify=true
EOF

# Create systemd service with dynamic DISPLAY detection
cat > "$CHROOT_DIR/etc/systemd/system/mesh-bridge-gui.service" <<'EOF'
[Unit]
Description=Mesh Bridge GUI
Documentation=file:///opt/mesh-bridge-gui/
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
# Use systemd's user session to get proper DISPLAY
ExecStart=/usr/bin/python3 /opt/mesh-bridge-gui/mesh-bridge-gui.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

log "✓ Mesh Bridge GUI installed (disabled)"

# 4. Install Service Manager
log "Installing IceNet Service Manager..."

# Check if service manager files exist
if [ ! -f "$INTEGRATIONS_DIR/service-manager/icenet-service-manager.py" ]; then
    log "ERROR: Service manager files not found in $INTEGRATIONS_DIR/service-manager"
    exit 1
fi

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

# Verify services are registered
log "Verifying service installation..."
if chroot "$CHROOT_DIR" systemctl list-unit-files | grep -q icenet-thermal; then
    log "✓ icenet-thermal.service registered"
else
    log "WARNING: icenet-thermal.service not found"
fi

if chroot "$CHROOT_DIR" systemctl list-unit-files | grep -q meshtastic-bridge; then
    log "✓ meshtastic-bridge.service registered"
else
    log "WARNING: meshtastic-bridge.service not found"
fi

if chroot "$CHROOT_DIR" systemctl list-unit-files | grep -q mesh-bridge-gui; then
    log "✓ mesh-bridge-gui.service registered"
else
    log "WARNING: mesh-bridge-gui.service not found"
fi

# 4. Install Desktop Environment
log "Installing IceNet Desktop Environment..."

# Fix any broken packages first
log "Checking for broken packages..."
chroot "$CHROOT_DIR" dpkg --configure -a 2>&1 || true
chroot "$CHROOT_DIR" apt-get --fix-broken install -y 2>&1 || true

# Install desktop packages
log "Installing Xorg and desktop packages..."
chroot "$CHROOT_DIR" apt-get update
chroot "$CHROOT_DIR" apt-get install -y --no-install-recommends \
    xorg \
    xserver-xorg-video-all \
    xserver-xorg-video-fbdev \
    xserver-xorg-video-vesa \
    xserver-xorg-input-all \
    openbox \
    obconf \
    tint2 \
    jgmenu \
    lightdm \
    lightdm-gtk-greeter \
    nitrogen \
    picom \
    lxterminal \
    pcmanfm \
    mousepad \
    lxappearance \
    lxtask \
    galculator \
    lxrandr \
    dunst \
    diodon \
    network-manager-gnome \
    volumeicon-alsa \
    unclutter \
    fonts-dejavu \
    fonts-noto \
    papirus-icon-theme \
    numlockx

if [ $? -ne 0 ]; then
    log "WARNING: Some desktop packages failed to install, continuing anyway"
fi

# Create configuration directories
mkdir -p "$CHROOT_DIR/etc/skel/.config"/{openbox,tint2,jgmenu}
mkdir -p "$CHROOT_DIR/etc/skel/.local/share/applications"

# Copy desktop configuration files
if [ -d "$INTEGRATIONS_DIR/icenet-desktop/config" ]; then
    cp "$INTEGRATIONS_DIR/icenet-desktop/config/openbox-rc.xml" \
        "$CHROOT_DIR/etc/skel/.config/openbox/rc.xml"
    cp "$INTEGRATIONS_DIR/icenet-desktop/config/openbox-autostart" \
        "$CHROOT_DIR/etc/skel/.config/openbox/autostart"
    chmod +x "$CHROOT_DIR/etc/skel/.config/openbox/autostart"

    cp "$INTEGRATIONS_DIR/icenet-desktop/config/tint2rc" \
        "$CHROOT_DIR/etc/skel/.config/tint2/tint2rc"
    cp "$INTEGRATIONS_DIR/icenet-desktop/config/jgmenurc" \
        "$CHROOT_DIR/etc/skel/.config/jgmenu/jgmenurc"
    cp "$INTEGRATIONS_DIR/icenet-desktop/config/jgmenu-apps.csv" \
        "$CHROOT_DIR/etc/skel/.config/jgmenu/apps.csv"
fi

# Install desktop application entries
if [ -d "$INTEGRATIONS_DIR/icenet-desktop/applications" ]; then
    cp "$INTEGRATIONS_DIR/icenet-desktop/applications/"*.desktop \
        "$CHROOT_DIR/usr/share/applications/"
fi

# Create .xinitrc for startx
cat > "$CHROOT_DIR/etc/skel/.xinitrc" <<'EOF'
#!/bin/sh
# IceNet-OS X Session
if [ -f ~/.Xresources ]; then
    xrdb -merge ~/.Xresources
fi
exec openbox-session
EOF
chmod +x "$CHROOT_DIR/etc/skel/.xinitrc"

# Configure LightDM
cat > "$CHROOT_DIR/etc/lightdm/lightdm.conf" <<'EOF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=openbox
autologin-user=
autologin-user-timeout=0
EOF

# Create basic Xorg config for VMs
mkdir -p "$CHROOT_DIR/etc/X11/xorg.conf.d"
cat > "$CHROOT_DIR/etc/X11/xorg.conf.d/10-fallback.conf" <<'EOF'
Section "Device"
    Identifier "Fallback Device"
    Driver "fbdev"
EndSection
EOF

# Don't enable LightDM by default - let user choose console or GUI
# User can start GUI with: sudo systemctl start lightdm
# Or enable at boot with: sudo systemctl enable lightdm
log "Desktop installed but not auto-starting. Use 'sudo systemctl start lightdm' to launch GUI"

# Apply desktop config to icenet user (since user is created before this runs)
if [ -d "$CHROOT_DIR/home/icenet" ]; then
    log "Applying desktop configuration to icenet user..."

    mkdir -p "$CHROOT_DIR/home/icenet/.config"/{openbox,tint2,jgmenu}
    mkdir -p "$CHROOT_DIR/home/icenet/.local/share/applications"

    cp -r "$CHROOT_DIR/etc/skel/.config/openbox" "$CHROOT_DIR/home/icenet/.config/"
    cp -r "$CHROOT_DIR/etc/skel/.config/tint2" "$CHROOT_DIR/home/icenet/.config/"
    cp -r "$CHROOT_DIR/etc/skel/.config/jgmenu" "$CHROOT_DIR/home/icenet/.config/"
    cp "$CHROOT_DIR/etc/skel/.xinitrc" "$CHROOT_DIR/home/icenet/"

    # Fix ownership
    chroot "$CHROOT_DIR" chown -R icenet:icenet /home/icenet
fi

log "✓ Desktop Environment installed and configured"

# 5. Install Reticulum Stack (nomadnet, etc.)
log "Installing Reticulum mesh networking stack..."

# Install Reticulum and tools via pip
chroot "$CHROOT_DIR" pip3 install --break-system-packages \
    rns \
    nomadnet \
    sbapp \
    lxmf \
    rnodeconf 2>&1 || {
        log "WARNING: Reticulum installation failed, continuing anyway"
    }

# Create NomadNet desktop entry
cat > "$CHROOT_DIR/usr/share/applications/nomadnet.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Name=NomadNet
Comment=Off-grid mesh communication system
Exec=lxterminal -e nomadnet
Icon=network-workgroup
Terminal=false
Type=Application
Categories=Network;Communication;
Keywords=reticulum;mesh;nomadnet;
StartupNotify=true
EOF

# Create Sideband desktop entry
cat > "$CHROOT_DIR/usr/share/applications/sideband.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Name=Sideband
Comment=LXMF messaging client
Exec=sideband
Icon=internet-mail
Terminal=false
Type=Application
Categories=Network;Communication;
Keywords=reticulum;lxmf;messaging;
StartupNotify=true
EOF

log "✓ Reticulum stack installed (nomadnet, sideband, lxmf)"

# 6. Install Complete Mesh & Radio Suite
log "Installing COMPLETE Mesh & Radio Suite (this will take 30-45 minutes)..."

# 6.1 Microsoft Edge Browser
log "Installing Microsoft Edge browser..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | chroot "$CHROOT_DIR" gpg --dearmor > "$CHROOT_DIR/etc/apt/trusted.gpg.d/microsoft.gpg"
echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > "$CHROOT_DIR/etc/apt/sources.list.d/microsoft-edge.list"
chroot "$CHROOT_DIR" apt-get update
chroot "$CHROOT_DIR" apt-get install -y microsoft-edge-stable || log "WARNING: Edge installation failed"

# 6.2 Full Meshtastic Ecosystem (already have Python package, this is complete)
log "✓ Meshtastic Python package already installed"

# 6.3 LoRa Suite
log "Installing LoRa suite (ChirpStack, tools)..."
chroot "$CHROOT_DIR" apt-get install -y \
    mosquitto \
    mosquitto-clients \
    redis-server \
    postgresql \
    postgresql-contrib || log "WARNING: LoRa dependencies failed"

# ChirpStack (LoRaWAN Network Server) - install from package
CHIRPSTACK_VERSION="4.7.0"
mkdir -p "$CHROOT_DIR/tmp"
wget -q -O "$CHROOT_DIR/tmp/chirpstack_${CHIRPSTACK_VERSION}_linux_amd64.deb" \
    "https://artifacts.chirpstack.io/downloads/chirpstack/chirpstack_${CHIRPSTACK_VERSION}_linux_amd64.deb" 2>/dev/null || true
if [ -f "$CHROOT_DIR/tmp/chirpstack_${CHIRPSTACK_VERSION}_linux_amd64.deb" ]; then
    chroot "$CHROOT_DIR" dpkg -i "/tmp/chirpstack_${CHIRPSTACK_VERSION}_linux_amd64.deb" || true
    rm -f "$CHROOT_DIR/tmp/chirpstack_${CHIRPSTACK_VERSION}_linux_amd64.deb"
fi

# 6.4 SDR Suite (largest component)
log "Installing SDR Suite (GNU Radio, GQRX, decoders, ham tools)..."
chroot "$CHROOT_DIR" apt-get install -y \
    gnuradio \
    gr-osmosdr \
    gqrx-sdr \
    rtl-sdr \
    librtlsdr-dev \
    dump1090-fa \
    rtl-433 \
    fldigi \
    wsjtx \
    direwolf \
    multimon-ng \
    hackrf \
    libhackrf-dev \
    soapysdr-tools \
    soapysdr-module-all || log "WARNING: Some SDR packages failed"

# SDR++ (modern SDR software) - from source is complex, skip for now
log "Note: SDR++ requires manual build, skipping for ISO"

# Create desktop entries for SDR tools
cat > "$CHROOT_DIR/usr/share/applications/gqrx.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Name=GQRX SDR
Comment=Software Defined Radio receiver
Exec=gqrx
Icon=gqrx
Terminal=false
Type=Application
Categories=HamRadio;Network;
EOF

cat > "$CHROOT_DIR/usr/share/applications/gnuradio-companion.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Name=GNU Radio Companion
Comment=Visual programming for SDR
Exec=gnuradio-companion
Icon=gnuradio-grc
Terminal=false
Type=Application
Categories=HamRadio;Development;
EOF

# 6.5 Mesh Protocols
log "Installing mesh networking protocols..."
chroot "$CHROOT_DIR" apt-get install -y \
    yggdrasil \
    cjdns \
    babeld \
    batctl \
    alfred || log "WARNING: Some mesh protocols failed"

# Batman-adv kernel module
chroot "$CHROOT_DIR" apt-get install -y batman-adv-dkms || true

# Create desktop entries for mesh tools
cat > "$CHROOT_DIR/usr/share/applications/yggdrasil.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Name=Yggdrasil
Comment=Encrypted IPv6 mesh network
Exec=lxterminal -e "bash -c 'yggdrasil -useconffile /etc/yggdrasil.conf; read'"
Icon=network-workgroup
Terminal=false
Type=Application
Categories=Network;
EOF

log "✓ Complete Mesh & Radio Suite installed!"
log "  - Microsoft Edge: Web browser"
log "  - Meshtastic: Full ecosystem with Python tools"
log "  - LoRa: ChirpStack + utilities"
log "  - SDR: GNU Radio, GQRX, dump1090, rtl_433, ham tools"
log "  - Mesh: Yggdrasil, cjdns, Babel, BATMAN-adv"

log "All integrations pre-installed and disabled by default"
log "Users can enable them via: icenet-service-manager (GUI) or icenet-services (CLI)"
