#!/bin/bash
# IceNet-OS Integrations Installer
#
# Install integrated software components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${INSTALL_PREFIX:-/opt/icenet}"
BIN_DIR="${BIN_DIR:-/usr/bin}"
SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"
CONFIG_DIR="${CONFIG_DIR:-/etc/icenet}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

install_thermal_mgmt() {
    log_info "Installing Thermal Management System..."

    # Clone repository if not exists
    if [ ! -d "$INSTALL_PREFIX/thermal-mgmt" ]; then
        git clone https://github.com/IceNet-01/thermal-management-system.git \
            "$INSTALL_PREFIX/thermal-mgmt"
    fi

    cd "$INSTALL_PREFIX/thermal-mgmt"

    # Install Python dependencies
    pip3 install -r requirements.txt

    # Copy systemd service
    cp "$SCRIPT_DIR/thermal-mgmt/icenet-thermal.service" "$SYSTEMD_DIR/"

    # Create wrapper scripts
    cat > "$BIN_DIR/icenet-thermal-daemon" <<'EOF'
#!/bin/bash
cd /opt/icenet/thermal-mgmt
exec python3 thermal_management.py
EOF

    cat > "$BIN_DIR/icenet-thermal-gui" <<'EOF'
#!/bin/bash
cd /opt/icenet/thermal-mgmt
exec python3 thermal_management.py --gui
EOF

    chmod +x "$BIN_DIR/icenet-thermal-daemon"
    chmod +x "$BIN_DIR/icenet-thermal-gui"

    # Create config directory
    mkdir -p "$CONFIG_DIR"
    mkdir -p /var/lib/icenet/thermal

    # Default configuration
    if [ ! -f "$CONFIG_DIR/thermal-mgmt.conf" ]; then
        cat > "$CONFIG_DIR/thermal-mgmt.conf" <<'EOF'
[thermal]
heat_threshold = 0.0
stop_threshold = 5.0
cpu_load_percent = 70
check_interval = 10
enable_gui = false

[logging]
log_level = INFO
log_to_journal = true
EOF
    fi

    # Reload systemd
    systemctl daemon-reload

    log_success "Thermal Management System installed"
    log_info "Enable with: sudo systemctl enable icenet-thermal"
}

install_meshtastic_bridge() {
    log_info "Installing Meshtastic Bridge (Headless)..."

    # Clone repository if not exists
    if [ ! -d "$INSTALL_PREFIX/meshtastic-bridge" ]; then
        git clone https://github.com/IceNet-01/meshtastic-bridge-headless.git \
            "$INSTALL_PREFIX/meshtastic-bridge"
    fi

    cd "$INSTALL_PREFIX/meshtastic-bridge"

    # Install Python dependencies
    pip3 install meshtastic>=2.7.0 pyserial>=3.5 rich>=14.2.0

    # Create service user
    if ! id meshtastic-bridge >/dev/null 2>&1; then
        useradd -r -s /bin/false -d /var/lib/icenet/meshtastic-bridge meshtastic-bridge
        usermod -a -G dialout meshtastic-bridge
    fi

    # Copy systemd service
    cp "$SCRIPT_DIR/meshtastic-bridge/meshtastic-bridge.service" "$SYSTEMD_DIR/"

    # Create wrapper script
    cat > "$BIN_DIR/meshtastic-bridge-daemon" <<'EOF'
#!/bin/bash
cd /opt/icenet/meshtastic-bridge
exec python3 bridge.py --config /etc/icenet/meshtastic-bridge.conf
EOF

    chmod +x "$BIN_DIR/meshtastic-bridge-daemon"

    # Create directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p /var/lib/icenet/meshtastic-bridge
    chown meshtastic-bridge:meshtastic-bridge /var/lib/icenet/meshtastic-bridge

    # Default configuration
    if [ ! -f "$CONFIG_DIR/meshtastic-bridge.conf" ]; then
        cat > "$CONFIG_DIR/meshtastic-bridge.conf" <<'EOF'
[bridge]
auto_detect = true
dedup_window_seconds = 600
max_message_cache = 10000
reconnect_min_delay = 2
reconnect_max_delay = 32
max_consecutive_failures = 3
health_check_interval = 30
status_file = /var/lib/icenet/meshtastic-bridge/status.json

[logging]
log_level = INFO
log_to_journal = true
EOF
    fi

    # Reload systemd
    systemctl daemon-reload

    log_success "Meshtastic Bridge installed"
    log_warning "Service is DISABLED by default - this is optional software"
    log_info "Enable with: sudo systemctl enable --now meshtastic-bridge"
}

install_mesh_bridge_gui() {
    log_info "Installing Mesh Bridge GUI..."

    # Check for Node.js
    if ! command -v node >/dev/null 2>&1; then
        log_warning "Node.js not found. Installing..."
        # Install Node.js (version check needed)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi

    # Clone repository if not exists
    if [ ! -d "$INSTALL_PREFIX/mesh-bridge-gui" ]; then
        git clone https://github.com/IceNet-01/Mesh-Bridge-GUI.git \
            "$INSTALL_PREFIX/mesh-bridge-gui"
    fi

    cd "$INSTALL_PREFIX/mesh-bridge-gui"

    # Install dependencies and build
    npm install
    npm run build

    # Create launcher script
    cat > "$BIN_DIR/mesh-bridge-gui" <<'EOF'
#!/bin/bash
cd /opt/icenet/mesh-bridge-gui
exec npm start
EOF

    chmod +x "$BIN_DIR/mesh-bridge-gui"

    # Install desktop entry
    mkdir -p /usr/share/applications
    cp "$SCRIPT_DIR/mesh-bridge-gui/mesh-bridge-gui.desktop" \
        /usr/share/applications/

    log_success "Mesh Bridge GUI installed"
    log_info "Launch with: mesh-bridge-gui"
}

install_desktop() {
    log_info "Installing Desktop Environment..."

    cd "$SCRIPT_DIR/icenet-desktop"
    bash install-desktop.sh

    log_success "Desktop Environment installed"
    log_info "Reboot and select 'Desktop GUI' from boot menu"
    log_info "Or enable auto-start: sudo systemctl enable lightdm"
}

show_menu() {
    echo ""
    echo "======================================"
    echo "  IceNet-OS Integrations Installer"
    echo "======================================"
    echo ""
    echo "1. Install Thermal Management System"
    echo "2. Install Meshtastic Bridge (Headless)"
    echo "3. Install Mesh Bridge GUI"
    echo "4. Install Desktop Environment"
    echo "5. Install All"
    echo "6. Exit"
    echo ""
    read -p "Select option [1-6]: " choice

    case $choice in
        1)
            install_thermal_mgmt
            ;;
        2)
            install_meshtastic_bridge
            ;;
        3)
            install_mesh_bridge_gui
            ;;
        4)
            install_desktop
            ;;
        5)
            install_thermal_mgmt
            install_meshtastic_bridge
            install_mesh_bridge_gui
            install_desktop
            ;;
        6)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid option"
            show_menu
            ;;
    esac
}

# Main
check_root

log_info "IceNet-OS Integrations Installer"
log_info "This will install integrated software components"
echo ""

if [ "$1" = "--all" ]; then
    install_thermal_mgmt
    install_meshtastic_bridge
    install_mesh_bridge_gui
    install_desktop
elif [ "$1" = "--thermal" ]; then
    install_thermal_mgmt
elif [ "$1" = "--bridge" ]; then
    install_meshtastic_bridge
elif [ "$1" = "--gui" ]; then
    install_mesh_bridge_gui
elif [ "$1" = "--desktop" ]; then
    install_desktop
else
    show_menu
fi

echo ""
log_success "Installation complete!"
echo ""
log_info "To enable services:"
echo "  Thermal Management: sudo systemctl enable icenet-thermal"
echo "  Meshtastic Bridge:  sudo systemctl enable meshtastic-bridge"
echo "  Desktop Environment: sudo systemctl enable lightdm"
echo ""
log_info "To start services:"
echo "  sudo systemctl start icenet-thermal"
echo "  sudo systemctl start meshtastic-bridge"
echo "  sudo systemctl start lightdm"
echo ""
log_info "Launch GUI applications:"
echo "  Thermal GUI:     icenet-thermal-gui"
echo "  Mesh Bridge GUI: mesh-bridge-gui"
echo "  Desktop:         startx  (or reboot and select from boot menu)"
