#!/bin/bash
# IceNet-OS Desktop Environment Installer
#
# Installs lightweight desktop environment with:
# - Xorg display server
# - Openbox window manager
# - tint2 panel (taskbar)
# - jgmenu start menu
# - LightDM display manager
# - All application launchers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="/opt/icenet"

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

install_packages() {
    log_info "Installing desktop environment packages..."

    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt-get"
        apt-get update
        apt-get install -y \
            xorg \
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
            clipit \
            unclutter \
            fonts-dejavu \
            papirus-icon-theme \
            numlockx
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
        pacman -Syu --noconfirm \
            xorg-server \
            xorg-xinit \
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
            clipit \
            unclutter \
            ttf-dejavu \
            papirus-icon-theme \
            numlockx
    else
        log_warning "Unknown package manager. Trying ice-pkg..."
        # Use IceNet-OS package manager when available
        ice-pkg install desktop-environment
    fi

    log_success "Packages installed"
}

configure_desktop() {
    log_info "Configuring desktop environment..."

    # Create configuration directories
    mkdir -p /etc/skel/.config/{openbox,tint2,jgmenu}
    mkdir -p /etc/skel/.local/share/applications

    # Copy configuration files
    cp "$SCRIPT_DIR/config/openbox-rc.xml" /etc/skel/.config/openbox/rc.xml
    cp "$SCRIPT_DIR/config/openbox-autostart" /etc/skel/.config/openbox/autostart
    chmod +x /etc/skel/.config/openbox/autostart

    cp "$SCRIPT_DIR/config/tint2rc" /etc/skel/.config/tint2/tint2rc
    cp "$SCRIPT_DIR/config/jgmenurc" /etc/skel/.config/jgmenu/jgmenurc
    cp "$SCRIPT_DIR/config/jgmenu-apps.csv" /etc/skel/.config/jgmenu/apps.csv

    # Install desktop entries
    mkdir -p /usr/share/applications
    cp "$SCRIPT_DIR/applications/"*.desktop /usr/share/applications/

    # Create .xinitrc for startx
    cat > /etc/skel/.xinitrc <<'EOF'
#!/bin/sh
# IceNet-OS X Session

# Merge X resources
if [ -f ~/.Xresources ]; then
    xrdb -merge ~/.Xresources
fi

# Start desktop environment
exec openbox-session
EOF

    chmod +x /etc/skel/.xinitrc

    log_success "Desktop configured"
}

configure_lightdm() {
    log_info "Configuring LightDM display manager..."

    # Configure LightDM
    cat > /etc/lightdm/lightdm.conf <<EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=openbox
autologin-user=
autologin-user-timeout=0
session-wrapper=/etc/lightdm/Xsession
display-setup-script=
greeter-setup-script=
pam-service=lightdm
pam-autologin-service=lightdm-autologin
pam-greeter-service=lightdm-greeter

[XDMCPServer]
enabled=false

[VNCServer]
enabled=false
EOF

    # Configure greeter
    mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d
    cat > /etc/lightdm/lightdm-gtk-greeter.conf.d/01-icenet.conf <<EOF
[greeter]
theme-name=Adwaita-dark
icon-theme-name=Papirus-Dark
font-name=Sans 11
background=/usr/share/backgrounds/icenet-default.jpg
indicators=~host;~spacer;~clock;~spacer;~session;~power
clock-format=%H:%M
position=50%,center 50%,center
EOF

    log_success "LightDM configured"
}

install_boot_menu() {
    log_info "Installing boot menu..."

    # Copy boot menu script
    cp "$SCRIPT_DIR/scripts/icenet-boot-menu" /usr/local/bin/
    chmod +x /usr/local/bin/icenet-boot-menu

    # Create version file
    echo "0.1.0" > /etc/icenet-version

    # Add to system profile for console boot
    cat >> /etc/profile.d/icenet-boot.sh <<'EOF'
# IceNet-OS Boot Menu
# Show GUI/Shell selection on first console login after boot

if [ -z "$ICENET_BOOT_MENU_SHOWN" ] && [ "$EUID" -eq 0 ] && tty | grep -q "tty1"; then
    export ICENET_BOOT_MENU_SHOWN=1
    /usr/local/bin/icenet-boot-menu
fi
EOF

    chmod +x /etc/profile.d/icenet-boot.sh

    log_success "Boot menu installed"
}

configure_default_user() {
    log_info "Applying desktop configuration to existing users..."

    # Apply to home directories
    for home in /home/*; do
        if [ -d "$home" ]; then
            user=$(basename "$home")
            log_info "Configuring desktop for user: $user"

            # Copy configuration if not exists
            sudo -u "$user" mkdir -p "$home/.config"/{openbox,tint2,jgmenu}
            sudo -u "$user" mkdir -p "$home/.local/share/applications"

            if [ ! -f "$home/.config/openbox/rc.xml" ]; then
                sudo -u "$user" cp /etc/skel/.config/openbox/rc.xml "$home/.config/openbox/"
            fi

            if [ ! -f "$home/.config/openbox/autostart" ]; then
                sudo -u "$user" cp /etc/skel/.config/openbox/autostart "$home/.config/openbox/"
                chmod +x "$home/.config/openbox/autostart"
            fi

            if [ ! -f "$home/.config/tint2/tint2rc" ]; then
                sudo -u "$user" cp /etc/skel/.config/tint2/tint2rc "$home/.config/tint2/"
            fi

            if [ ! -f "$home/.config/jgmenu/jgmenurc" ]; then
                sudo -u "$user" cp /etc/skel/.config/jgmenu/jgmenurc "$home/.config/jgmenu/"
            fi

            if [ ! -f "$home/.config/jgmenu/apps.csv" ]; then
                sudo -u "$user" cp /etc/skel/.config/jgmenu/apps.csv "$home/.config/jgmenu/"
            fi

            if [ ! -f "$home/.xinitrc" ]; then
                sudo -u "$user" cp /etc/skel/.xinitrc "$home/"
                chmod +x "$home/.xinitrc"
            fi
        fi
    done

    log_success "User configurations applied"
}

# Main installation
main() {
    log_info "IceNet-OS Desktop Environment Installer"
    echo ""

    check_root

    log_info "This will install:"
    echo "  - Xorg display server"
    echo "  - Openbox window manager"
    echo "  - tint2 panel (taskbar)"
    echo "  - jgmenu start menu"
    echo "  - LightDM login manager"
    echo "  - Essential desktop applications"
    echo "  - Boot menu (GUI/Shell selection)"
    echo ""
    echo "Estimated download size: ~200MB"
    echo "Installation size: ~300MB"
    echo ""

    read -p "Continue with installation? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi

    install_packages
    configure_desktop
    configure_lightdm
    install_boot_menu
    configure_default_user

    echo ""
    log_success "IceNet-OS Desktop Environment installed successfully!"
    echo ""
    echo "To start the desktop:"
    echo "  1. Reboot and select 'Desktop GUI' from boot menu"
    echo "  2. Or enable auto-start: sudo systemctl enable lightdm"
    echo "  3. Or start manually: sudo systemctl start lightdm"
    echo "  4. Or from console: startx"
    echo ""
    echo "Boot Menu Options:"
    echo "  - Console Shell (default if no input)"
    echo "  - Desktop GUI"
    echo ""
    echo "Desktop Features:"
    echo "  - Click bottom-left for Start Menu"
    echo "  - Right-click desktop for quick menu"
    echo "  - Super+T for terminal, Super+E for file manager"
    echo "  - All IceNet-OS tools available in start menu"
    echo ""
}

main "$@"
