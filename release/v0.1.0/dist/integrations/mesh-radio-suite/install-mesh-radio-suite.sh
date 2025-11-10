#!/bin/bash
# IceNet-OS Mesh & Radio Suite Installer
#
# Complete turnkey solution for mesh networking, LoRa, and SDR

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Detect architecture
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="armhf" ;;
    esac
}

install_edge_browser() {
    log_info "Installing Microsoft Edge browser..."

    if command -v microsoft-edge >/dev/null 2>&1; then
        log_success "Edge already installed"
        return 0
    fi

    # Add Microsoft repository
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg

    echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list

    apt-get update
    apt-get install -y microsoft-edge-stable

    # Create desktop entry
    cat > /usr/share/applications/microsoft-edge.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Microsoft Edge
Comment=Browse the web
Exec=/usr/bin/microsoft-edge-stable %U
Icon=microsoft-edge
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;
StartupNotify=true
EOF

    log_success "Edge browser installed"
}

install_meshtastic() {
    log_info "Installing Meshtastic ecosystem..."

    # Install Python dependencies
    apt-get install -y python3-pip python3-venv

    # Install Meshtastic Python
    pip3 install --upgrade meshtastic

    # Install Meshtastic Flasher (GUI tool)
    pip3 install meshtastic-flasher

    # Install platformio for firmware development
    pip3 install platformio

    # Install web interface dependencies
    apt-get install -y nodejs npm
    npm install -g http-server

    # Clone Meshtastic web interface
    if [ ! -d /opt/meshtastic-web ]; then
        git clone https://github.com/meshtastic/meshtastic-web.git /opt/meshtastic-web
        cd /opt/meshtastic-web
        npm install
        npm run build
    fi

    # Create desktop entries
    mkdir -p /usr/share/applications

    cat > /usr/share/applications/meshtastic-cli.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Meshtastic CLI
Comment=Meshtastic command-line interface
Exec=lxterminal -e 'bash -c "meshtastic --help; read -p \"Press Enter to close...\""'
Icon=network-wireless
Terminal=false
Type=Application
Categories=Network;HamRadio;
Keywords=meshtastic;lora;mesh;
StartupNotify=true
EOF

    cat > /usr/share/applications/meshtastic-flasher.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Meshtastic Flasher
Comment=Flash Meshtastic firmware to devices
Exec=meshtastic-flasher
Icon=system-software-update
Terminal=false
Type=Application
Categories=System;Development;
Keywords=meshtastic;firmware;flash;
StartupNotify=true
EOF

    cat > /usr/share/applications/meshtastic-web.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Meshtastic Web Interface
Comment=Browser-based Meshtastic configuration
Exec=bash -c 'cd /opt/meshtastic-web && http-server ./dist -p 8080 & sleep 2 && microsoft-edge http://localhost:8080'
Icon=applications-internet
Terminal=false
Type=Application
Categories=Network;Settings;
Keywords=meshtastic;web;config;
StartupNotify=true
EOF

    log_success "Meshtastic installed"
}

install_reticulum() {
    log_info "Installing Reticulum stack..."

    # Install Reticulum
    pip3 install rns

    # Install NomadNet
    pip3 install nomadnet

    # Install Sideband
    pip3 install sbapp

    # Install LXMF tools
    pip3 install lxmf

    # Install RNode utilities
    pip3 install rnodeconf

    # Create config directory
    mkdir -p /etc/reticulum
    mkdir -p ~/.reticulum

    # Default Reticulum config
    cat > ~/.reticulum/config <<'EOF'
[reticulum]
  enable_transport = False
  share_instance = Yes
  shared_instance_port = 37428
  instance_control_port = 37429

[logging]
  loglevel = 4

[interfaces]
  [[Default Interface]]
    type = AutoInterface
    enabled = True

  [[RNode LoRa Interface]]
    type = RNodeInterface
    enabled = False
    port = /dev/ttyUSB0
    frequency = 915000000
    bandwidth = 125000
    txpower = 7
    spreadingfactor = 8
    codingrate = 5
EOF

    # Desktop entries
    cat > /usr/share/applications/nomadnet.desktop <<'EOF'
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

    cat > /usr/share/applications/sideband.desktop <<'EOF'
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

    cat > /usr/share/applications/rnodeconf.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=RNode Configuration
Comment=Configure RNode devices
Exec=lxterminal -e 'bash -c "rnodeconf --help; read"'
Icon=preferences-system
Terminal=false
Type=Application
Categories=System;Settings;
Keywords=rnode;lora;config;
StartupNotify=true
EOF

    log_success "Reticulum stack installed"
}

install_lora_suite() {
    log_info "Installing LoRa software suite..."

    # Install build dependencies
    apt-get install -y build-essential git cmake libusb-1.0-0-dev

    # Install ChirpStack
    apt-get install -y apt-transport-https dirmngr
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1CE2AFD36DBCCA00

    echo "deb https://artifacts.chirpstack.io/packages/4.x/deb stable main" | tee /etc/apt/sources.list.d/chirpstack.list
    apt-get update
    apt-get install -y chirpstack-gateway-bridge chirpstack

    # Install sx1302_hal (for SX1302/1303 concentrators)
    if [ ! -d /opt/lora/sx1302_hal ]; then
        mkdir -p /opt/lora
        cd /opt/lora
        git clone https://github.com/Lora-net/sx1302_hal.git
        cd sx1302_hal
        make clean all
    fi

    # Install PyLora
    pip3 install pylora

    # Install The Things Stack (TTN) CLI
    if [ ! -f /usr/local/bin/ttn-lw-cli ]; then
        wget -O /tmp/ttn-lw-cli.tar.gz "https://github.com/TheThingsNetwork/lorawan-stack/releases/download/v3.27.1/lorawan-stack_3.27.1_linux_${ARCH}.tar.gz"
        tar -xzf /tmp/ttn-lw-cli.tar.gz -C /usr/local/bin/ ttn-lw-cli
        chmod +x /usr/local/bin/ttn-lw-cli
    fi

    # Desktop entries
    cat > /usr/share/applications/chirpstack-gateway.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=ChirpStack Gateway
Comment=LoRaWAN gateway bridge
Exec=lxterminal -e 'bash -c "sudo systemctl status chirpstack-gateway-bridge; read"'
Icon=network-server
Terminal=false
Type=Application
Categories=Network;System;
Keywords=lorawan;gateway;chirpstack;
StartupNotify=true
EOF

    cat > /usr/share/applications/chirpstack-console.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=ChirpStack Console
Comment=Open ChirpStack web interface
Exec=microsoft-edge http://localhost:8080
Icon=applications-internet
Terminal=false
Type=Application
Categories=Network;Settings;
Keywords=lorawan;chirpstack;console;
StartupNotify=true
EOF

    log_success "LoRa suite installed"
}

install_sdr_suite() {
    log_info "Installing SDR software suite (this may take a while)..."

    # Install core SDR libraries
    apt-get install -y \
        libusb-1.0-0-dev \
        libasound2-dev \
        libpulse-dev \
        libfftw3-dev \
        libvolk2-dev \
        libboost-all-dev \
        swig \
        doxygen

    # Install RTL-SDR
    apt-get install -y rtl-sdr librtlsdr-dev

    # Install SoapySDR
    apt-get install -y soapysdr-tools

    # Install GNU Radio
    apt-get install -y gnuradio

    # Install GQRX
    apt-get install -y gqrx-sdr

    # Install SDR++ (from source or PPA)
    if ! command -v sdrpp >/dev/null 2>&1; then
        log_info "Building SDR++ from source..."
        apt-get install -y libglfw3-dev libglew-dev

        if [ ! -d /opt/SDRPlusPlus ]; then
            git clone https://github.com/AlexandreRouma/SDRPlusPlus.git /opt/SDRPlusPlus
            cd /opt/SDRPlusPlus
            mkdir build && cd build
            cmake ..
            make -j$(nproc)
            make install
        fi
    fi

    # Install dump1090 for ADS-B
    if [ ! -d /opt/dump1090 ]; then
        git clone https://github.com/flightaware/dump1090.git /opt/dump1090
        cd /opt/dump1090
        make
        cp dump1090 /usr/local/bin/
    fi

    # Install rtl_433
    apt-get install -y rtl-433

    # Install Inspectrum
    apt-get install -y inspectrum

    # Install Universal Radio Hacker
    pip3 install urh

    # Install Ham Radio software
    apt-get install -y \
        fldigi \
        wsjtx \
        direwolf \
        xastir

    # Install HackRF tools
    apt-get install -y hackrf libhackrf-dev

    # Install LimeSDR tools
    apt-get install -y limesuite limesuite-udev liblimesuite-dev

    # Desktop entries for SDR software
    # GQRX already has desktop entry from package

    cat > /usr/share/applications/sdrpp.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=SDR++
Comment=Modern SDR software
Exec=sdrpp
Icon=radio
Terminal=false
Type=Application
Categories=HamRadio;Network;
Keywords=sdr;radio;receiver;
StartupNotify=true
EOF

    cat > /usr/share/applications/gnuradio-companion.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=GNU Radio Companion
Comment=Visual SDR flowgraph design
Exec=gnuradio-companion
Icon=gnuradio-grc
Terminal=false
Type=Application
Categories=HamRadio;Development;
Keywords=sdr;gnuradio;flowgraph;
StartupNotify=true
EOF

    cat > /usr/share/applications/dump1090.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=dump1090 (ADS-B)
Comment=Aircraft tracking via ADS-B
Exec=lxterminal -e 'bash -c "dump1090 --interactive --net; read"'
Icon=applications-science
Terminal=false
Type=Application
Categories=HamRadio;Network;
Keywords=adsb;aircraft;aviation;
StartupNotify=true
EOF

    cat > /usr/share/applications/urh.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Name=Universal Radio Hacker
Comment=Investigate wireless protocols
Exec=urh
Icon=radio
Terminal=false
Type=Application
Categories=HamRadio;Development;
Keywords=sdr;protocol;analysis;
StartupNotify=true
EOF

    # Ham radio apps usually install their own desktop files

    log_success "SDR suite installed"
}

install_mesh_protocols() {
    log_info "Installing mesh networking protocols..."

    # Install Yggdrasil
    if ! command -v yggdrasil >/dev/null 2>&1; then
        wget -O /tmp/yggdrasil.deb "https://github.com/yggdrasil-network/yggdrasil-go/releases/download/v0.5.2/yggdrasil-0.5.2-linux-${ARCH}.deb"
        dpkg -i /tmp/yggdrasil.deb || apt-get install -f -y
    fi

    # Install cjdns
    apt-get install -y cjdns

    # Install Babel
    apt-get install -y babeld

    # Install BATMAN-adv
    apt-get install -y batctl

    log_success "Mesh protocols installed"
}

show_menu() {
    clear
    echo -e "${CYAN}"
    cat <<'EOF'
  ╔══════════════════════════════════════════════╗
  ║  IceNet-OS Mesh & Radio Suite Installer     ║
  ╚══════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo "Select components to install:"
    echo ""
    echo "  1) Microsoft Edge Browser"
    echo "  2) Meshtastic Ecosystem"
    echo "  3) Reticulum Stack (NomadNet, Sideband)"
    echo "  4) LoRa Software Suite"
    echo "  5) SDR Software Suite"
    echo "  6) Mesh Networking Protocols"
    echo "  7) Install Everything"
    echo "  8) Exit"
    echo ""
    read -p "Enter selection [1-8]: " choice
    echo ""

    case $choice in
        1) install_edge_browser ;;
        2) install_meshtastic ;;
        3) install_reticulum ;;
        4) install_lora_suite ;;
        5) install_sdr_suite ;;
        6) install_mesh_protocols ;;
        7) install_everything ;;
        8) exit 0 ;;
        *) log_error "Invalid selection"; sleep 2; show_menu ;;
    esac
}

install_everything() {
    log_info "Installing complete Mesh & Radio Suite..."
    install_edge_browser
    install_meshtastic
    install_reticulum
    install_lora_suite
    install_sdr_suite
    install_mesh_protocols
}

# Main
check_root
detect_arch

log_info "IceNet-OS Mesh & Radio Suite Installer"
echo ""

if [ "$1" = "--all" ]; then
    install_everything
elif [ "$1" = "--browser" ]; then
    install_edge_browser
elif [ "$1" = "--meshtastic" ]; then
    install_meshtastic
elif [ "$1" = "--reticulum" ]; then
    install_reticulum
elif [ "$1" = "--lora" ]; then
    install_lora_suite
elif [ "$1" = "--sdr" ]; then
    install_sdr_suite
elif [ "$1" = "--mesh" ]; then
    install_mesh_protocols
else
    show_menu
fi

echo ""
log_success "Installation complete!"
echo ""
log_info "Installed software can be found in the start menu under:"
echo "  - Internet (Edge browser)"
echo "  - Mesh Networking (Meshtastic, Reticulum, protocols)"
echo "  - LoRa Tools (ChirpStack, gateways)"
echo "  - SDR Tools (GQRX, GNU Radio, decoders)"
echo ""
log_info "Quick start guides:"
echo "  Meshtastic: meshtastic --help"
echo "  NomadNet: nomadnet"
echo "  GQRX: gqrx"
echo "  GNU Radio: gnuradio-companion"
echo ""
log_info "For detailed documentation, see:"
echo "  /opt/icenet/integrations/mesh-radio-suite/README.md"
