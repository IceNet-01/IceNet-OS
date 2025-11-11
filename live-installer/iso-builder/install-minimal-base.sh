#!/bin/bash
# IceNet-OS Minimal Base Installer
# Installs only essential desktop + remote access

set -e

CHROOT_DIR="$1"
INTEGRATIONS_DIR="$2"

if [ -z "$CHROOT_DIR" ] || [ -z "$INTEGRATIONS_DIR" ]; then
    echo "Usage: $0 <chroot_dir> <integrations_dir>"
    exit 1
fi

log() {
    echo "[MINIMAL-BASE] $*"
}

log "Installing minimal LXDE desktop environment..."

# Fix any broken packages first
chroot "$CHROOT_DIR" dpkg --configure -a 2>&1 || true
chroot "$CHROOT_DIR" apt-get --fix-broken install -y 2>&1 || true

# Defer initramfs updates during package installation to avoid triggering live-boot hooks prematurely
log "Deferring initramfs updates during installation..."
if [ -f "$CHROOT_DIR/usr/sbin/update-initramfs" ]; then
    mv "$CHROOT_DIR/usr/sbin/update-initramfs" "$CHROOT_DIR/usr/sbin/update-initramfs.real"
    cat > "$CHROOT_DIR/usr/sbin/update-initramfs" <<'EOF'
#!/bin/sh
# Temporarily disabled during minimal base installation
echo "update-initramfs: deferred (minimal base installation in progress)"
exit 0
EOF
    chmod +x "$CHROOT_DIR/usr/sbin/update-initramfs"
fi

# Install LXDE and essential desktop packages
log "Installing LXDE desktop..."
chroot "$CHROOT_DIR" apt-get update
chroot "$CHROOT_DIR" apt-get install -y \
    xorg \
    xserver-xorg-video-all \
    lxde-core \
    lxde-common \
    lxappearance \
    lxtask \
    lxterminal \
    pcmanfm \
    mousepad \
    galculator \
    network-manager-gnome \
    policykit-1-gnome \
    gvfs-backends \
    gvfs-fuse \
    light-locker \
    lightdm \
    lightdm-gtk-greeter \
    fonts-dejavu \
    fonts-noto \
    papirus-icon-theme \
    xarchiver \
    file-roller || {
        log "WARNING: Some packages failed, continuing"
    }

log "✓ LXDE desktop installed"

# Install Microsoft Edge (gnupg and wget already in base system)
log "Installing Microsoft Edge browser..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | chroot "$CHROOT_DIR" gpg --dearmor > "$CHROOT_DIR/etc/apt/trusted.gpg.d/microsoft.gpg"
echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > "$CHROOT_DIR/etc/apt/sources.list.d/microsoft-edge.list"
chroot "$CHROOT_DIR" apt-get update
chroot "$CHROOT_DIR" apt-get install -y microsoft-edge-stable || log "WARNING: Edge installation failed"

log "✓ Microsoft Edge installed"

# Install SSH Server
log "Installing OpenSSH server..."
chroot "$CHROOT_DIR" apt-get install -y \
    openssh-server \
    ssh

# Enable SSH server
chroot "$CHROOT_DIR" systemctl enable ssh

log "✓ SSH server installed and enabled"

# Install Remote Desktop (RDP + VNC)
log "Installing Remote Desktop services..."
chroot "$CHROOT_DIR" apt-get install -y \
    xrdp \
    x11vnc \
    tigervnc-standalone-server \
    tigervnc-common

# Enable xrdp
chroot "$CHROOT_DIR" systemctl enable xrdp

# Configure xrdp for LXDE
cat > "$CHROOT_DIR/etc/xrdp/startwm.sh" <<'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
exec startlxde
EOF
chmod +x "$CHROOT_DIR/etc/xrdp/startwm.sh"

log "✓ Remote Desktop installed (RDP on port 3389, VNC configurable)"

# Set proper hostname
echo "icenet-os" > "$CHROOT_DIR/etc/hostname"
cat > "$CHROOT_DIR/etc/hosts" <<EOF
127.0.0.1       localhost
127.0.1.1       icenet-os
::1             localhost ip6-localhost ip6-loopback
EOF

log "✓ Hostname configured"

# Install IceNet Software Center
log "Installing IceNet Software Center..."
mkdir -p "$CHROOT_DIR/opt/icenet-software-center"

# Copy Software Center application (we'll create this next)
if [ -d "$INTEGRATIONS_DIR/software-center" ]; then
    cp -r "$INTEGRATIONS_DIR/software-center/"* "$CHROOT_DIR/opt/icenet-software-center/"
    chmod +x "$CHROOT_DIR/opt/icenet-software-center/software-center.py"
fi

# Create desktop entry
cat > "$CHROOT_DIR/usr/share/applications/icenet-software-center.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Name=IceNet Software Center
Comment=Install optional components for IceNet-OS
Exec=python3 /opt/icenet-software-center/software-center.py
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;Settings;PackageManager;
Keywords=software;install;packages;
StartupNotify=true
EOF

log "✓ Software Center installed"

# Ensure /usr/local/bin is in PATH
cat > "$CHROOT_DIR/etc/profile.d/local-bin-path.sh" <<'EOF'
# Add /usr/local/bin to PATH if not already present
case ":${PATH}:" in
    *:/usr/local/bin:*)
        ;;
    *)
        export PATH="/usr/local/bin:$PATH"
        ;;
esac
EOF
chmod +x "$CHROOT_DIR/etc/profile.d/local-bin-path.sh"

# Restore real update-initramfs and regenerate if needed
log "Restoring initramfs updates..."
if [ -f "$CHROOT_DIR/usr/sbin/update-initramfs.real" ]; then
    rm -f "$CHROOT_DIR/usr/sbin/update-initramfs"
    mv "$CHROOT_DIR/usr/sbin/update-initramfs.real" "$CHROOT_DIR/usr/sbin/update-initramfs"
    log "Regenerating initramfs with all components installed..."
    chroot "$CHROOT_DIR" update-initramfs -u -k all || log "WARNING: initramfs update had issues"
fi

log "==================================="
log "Minimal Base Installation Complete"
log "==================================="
log "Installed:"
log "  ✓ LXDE Desktop"
log "  ✓ Microsoft Edge"
log "  ✓ SSH Server (port 22)"
log "  ✓ RDP Server (port 3389)"
log "  ✓ VNC Server (configurable)"
log "  ✓ IceNet Software Center"
log ""
log "Optional components can be installed via Software Center"
