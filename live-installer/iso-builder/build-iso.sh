#!/bin/bash
# IceNet-OS ISO Builder
# Builds bootable ISO image for x86_64 systems

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/icenet-iso-build"
ISO_DIR="$BUILD_DIR/iso"
SQUASHFS_DIR="$BUILD_DIR/squashfs"
OUTPUT_DIR="$SCRIPT_DIR/output"
CACHE_DIR="$SCRIPT_DIR/cache"  # Cache directory for base system

# ISO naming with timestamp to prevent collisions
ISO_NAME="icenet-os-$(date +%Y%m%d-%H%M%S).iso"

# Build options (can be overridden with environment variables)
FAST_BUILD="${FAST_BUILD:-false}"        # Skip debootstrap if cache exists
FAST_COMPRESSION="${FAST_COMPRESSION:-false}"  # Use gzip instead of xz
PARALLEL_DOWNLOADS="${PARALLEL_DOWNLOADS:-4}"  # Parallel apt downloads

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Check requirements
check_requirements() {
    log "Checking requirements..."

    local missing=()

    command -v debootstrap >/dev/null || missing+=("debootstrap")
    command -v mksquashfs >/dev/null || missing+=("squashfs-tools")
    command -v grub-mkrescue >/dev/null || missing+=("grub-pc-bin grub-efi-amd64-bin")
    command -v xorriso >/dev/null || missing+=("xorriso")

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required packages: ${missing[*]}\nInstall with: apt-get install ${missing[*]}"
    fi

    if [ $(id -u) -ne 0 ]; then
        error "This script must be run as root"
    fi

    log "All requirements satisfied"
}

# Clean build directory
clean_build() {
    log "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$ISO_DIR"/{live,boot/grub}
    mkdir -p "$SQUASHFS_DIR"
    mkdir -p "$OUTPUT_DIR"
}

# Build base system
validate_cache() {
    local cache_path="$1"

    # Check if cache directory exists
    if [ ! -d "$cache_path" ]; then
        return 1
    fi

    # Check for essential directories
    for dir in usr etc var boot lib bin sbin; do
        if [ ! -d "$cache_path/$dir" ]; then
            log "WARNING: Cache missing directory: $dir"
            return 1
        fi
    done

    # Check for critical binaries
    for binary in usr/bin/apt-get usr/bin/dpkg usr/sbin/update-initramfs usr/bin/python3; do
        if [ ! -f "$cache_path/$binary" ]; then
            log "WARNING: Cache missing binary: $binary"
            return 1
        fi
    done

    # Check for kernel
    if ! ls "$cache_path/boot/vmlinuz-"* >/dev/null 2>&1; then
        log "WARNING: Cache missing kernel image"
        return 1
    fi

    # Check for initramfs
    if ! ls "$cache_path/boot/initrd.img-"* >/dev/null 2>&1; then
        log "WARNING: Cache missing initramfs"
        return 1
    fi

    # Check for live-boot components
    if [ ! -f "$cache_path/usr/share/initramfs-tools/scripts/live" ]; then
        log "WARNING: Cache missing live-boot components"
        return 1
    fi

    log "✓ Cache validation passed"
    return 0
}

build_base_system() {
    log "Building base system..."

    # Check for cached base system first (FAST_BUILD mode)
    if [ "$FAST_BUILD" = "true" ]; then
        if [ -d "$CACHE_DIR/base-system" ]; then
            log "Validating cached base system..."
            if validate_cache "$CACHE_DIR/base-system"; then
                log "Using cached base system (FAST MODE)"
                rsync -aAX "$CACHE_DIR/base-system/" "$SQUASHFS_DIR/"
                return
            else
                log "WARNING: Cache validation failed!"
                log "WARNING: Falling back to normal build (this will take longer)"
                log "TIP: Run a normal build first to create a valid cache"
                sleep 3
                # Fall through to normal build
            fi
        else
            log "WARNING: No cache found at $CACHE_DIR/base-system"
            log "WARNING: Falling back to normal build (this will take longer)"
            log "TIP: Run a normal build first to create cache for fast mode"
            sleep 3
            # Fall through to normal build
        fi
    fi

    # Use existing system or debootstrap
    if [ -d "/live/rootfs" ] && [ -f "/live/rootfs/usr/bin/apt-get" ]; then
        log "Using existing live system"
        rsync -aAX /live/rootfs/ "$SQUASHFS_DIR/" \
            --exclude=/proc/* \
            --exclude=/sys/* \
            --exclude=/dev/* \
            --exclude=/tmp/* \
            --exclude=/run/* \
            --exclude=/mnt/* \
            --exclude=/media/* \
            --exclude=/live/*
    elif [ -d "$SCRIPT_DIR/../../rootfs" ] && [ -f "$SCRIPT_DIR/../../rootfs/usr/bin/apt-get" ]; then
        log "Using IceNet-OS rootfs"
        rsync -aAX "$SCRIPT_DIR/../../rootfs/" "$SQUASHFS_DIR/"
    else
        log "Bootstrapping Debian base system (this will take 5-10 minutes)"

        # Use a fast mirror for better download speeds
        DEBIAN_MIRROR="http://deb.debian.org/debian/"

        debootstrap --arch=amd64 --variant=minbase \
            bookworm "$SQUASHFS_DIR" "$DEBIAN_MIRROR"

        # Enable parallel downloads in apt
        log "Configuring parallel downloads..."
        mkdir -p "$SQUASHFS_DIR/etc/apt/apt.conf.d"
        cat > "$SQUASHFS_DIR/etc/apt/apt.conf.d/99parallel" <<EOF
APT::Acquire::Queue-Mode "host";
APT::Acquire::Retries "3";
Binary::apt::APT::Get::Assume-Yes "true";
Binary::apt::APT::Get::force-yes "true";
EOF

        # Install essential packages
        log "Installing essential packages (with $PARALLEL_DOWNLOADS parallel downloads)..."
        chroot "$SQUASHFS_DIR" apt-get update

        # Pre-configure keyboard to avoid interactive prompts
        log "Pre-configuring keyboard layout (US)..."
        cat > "$SQUASHFS_DIR/tmp/keyboard-preseed.txt" <<'EOF'
keyboard-configuration keyboard-configuration/layoutcode string us
keyboard-configuration keyboard-configuration/layout select English (US)
keyboard-configuration keyboard-configuration/variant select English (US)
keyboard-configuration keyboard-configuration/model select Generic 105-key PC
keyboard-configuration keyboard-configuration/modelcode string pc105
keyboard-configuration keyboard-configuration/xkb-keymap select us
console-setup console-setup/charmap47 select UTF-8
EOF
        chroot "$SQUASHFS_DIR" debconf-set-selections /tmp/keyboard-preseed.txt
        rm -f "$SQUASHFS_DIR/tmp/keyboard-preseed.txt"

        # Configure non-interactive frontend to prevent all prompts
        echo 'debconf debconf/frontend select Noninteractive' | chroot "$SQUASHFS_DIR" debconf-set-selections

        # Prevent services from starting during package installation
        log "Configuring policy-rc.d to prevent service starts during build..."
        cat > "$SQUASHFS_DIR/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
# Prevent services from starting during package installation
exit 101
EOF
        chmod +x "$SQUASHFS_DIR/usr/sbin/policy-rc.d"

        chroot "$SQUASHFS_DIR" env DEBIAN_FRONTEND=noninteractive apt-get install -y \
            apt-transport-https \
            ca-certificates \
            initramfs-tools \
            locales

        # Generate en_US.UTF-8 locale to prevent locale warnings
        log "Generating en_US.UTF-8 locale..."
        echo "en_US.UTF-8 UTF-8" > "$SQUASHFS_DIR/etc/locale.gen"
        chroot "$SQUASHFS_DIR" locale-gen
        chroot "$SQUASHFS_DIR" update-locale LANG=en_US.UTF-8

        # Now that initramfs-tools is installed, defer initramfs generation during remaining package installation
        # (we'll regenerate it properly after all packages are installed)
        log "Configuring initramfs to defer updates..."
        mv "$SQUASHFS_DIR/usr/sbin/update-initramfs" "$SQUASHFS_DIR/usr/sbin/update-initramfs.real"
        cat > "$SQUASHFS_DIR/usr/sbin/update-initramfs" <<'EOF'
#!/bin/sh
# Temporarily disabled during package installation
echo "update-initramfs: deferred (will regenerate after package installation)"
exit 0
EOF
        chmod +x "$SQUASHFS_DIR/usr/sbin/update-initramfs"

        # Install core packages with initramfs updates deferred
        log "Installing core packages (initramfs generation deferred)..."
        chroot "$SQUASHFS_DIR" env DEBIAN_FRONTEND=noninteractive apt-get install -y -o Acquire::Queue-Mode=host \
            linux-image-amd64 \
            live-boot \
            live-boot-initramfs-tools \
            grub-efi-amd64-bin \
            grub-pc-bin \
            grub-common \
            grub2-common \
            network-manager \
            sudo \
            dialog \
            python3 \
            python3-gi \
            gir1.2-gtk-3.0 \
            xorriso \
            isolinux \
            systemd \
            systemd-sysv \
            gnupg \
            wget

        # Restore real update-initramfs and regenerate properly
        log "Restoring initramfs generation..."
        rm -f "$SQUASHFS_DIR/usr/sbin/update-initramfs"
        mv "$SQUASHFS_DIR/usr/sbin/update-initramfs.real" "$SQUASHFS_DIR/usr/sbin/update-initramfs"

        # Now regenerate initramfs with all packages in place
        log "Generating initramfs..."
        chroot "$SQUASHFS_DIR" update-initramfs -c -k all || {
            log "WARNING: initramfs generation had issues, trying alternative method..."
            chroot "$SQUASHFS_DIR" dpkg-reconfigure linux-image-amd64 || true
        }

        # Remove policy-rc.d so services can start normally on the live system
        log "Removing policy-rc.d..."
        rm -f "$SQUASHFS_DIR/usr/sbin/policy-rc.d"

        # Save to cache for future builds
        log "Caching base system for future builds..."
        mkdir -p "$CACHE_DIR"
        rm -rf "$CACHE_DIR/base-system"
        rsync -aAX "$SQUASHFS_DIR/" "$CACHE_DIR/base-system/"
        log "Base system cached to $CACHE_DIR/base-system"
    fi

    log "Base system ready"
}

# Setup default user
setup_default_user() {
    log "Setting up default user..."

    # Set hostname
    echo "icenet-os" > "$SQUASHFS_DIR/etc/hostname"

    # Set hosts file
    cat > "$SQUASHFS_DIR/etc/hosts" <<EOF
127.0.0.1       localhost
127.0.1.1       icenet-os
::1             localhost ip6-localhost ip6-loopback
EOF

    # Create icenet user
    chroot "$SQUASHFS_DIR" useradd -m -s /bin/bash -G sudo icenet

    # Set password to 'icenet'
    echo "icenet:icenet" | chroot "$SQUASHFS_DIR" chpasswd

    # Set root password to 'root'
    echo "root:root" | chroot "$SQUASHFS_DIR" chpasswd

    # Allow sudo without password for icenet user
    echo "icenet ALL=(ALL) NOPASSWD:ALL" > "$SQUASHFS_DIR/etc/sudoers.d/icenet"
    chmod 0440 "$SQUASHFS_DIR/etc/sudoers.d/icenet"

    log "Default user created: icenet/icenet (root/root)"
}

# Install IceNet components
install_icenet_components() {
    log "Installing IceNet components..."

    # Copy init system
    if [ -f "$SCRIPT_DIR/../../init/icenet-init" ]; then
        cp "$SCRIPT_DIR/../../init/icenet-init" "$SQUASHFS_DIR/sbin/"
        chmod +x "$SQUASHFS_DIR/sbin/icenet-init"
    fi

    # Copy package manager
    if [ -f "$SCRIPT_DIR/../../pkgmgr/ice-pkg" ]; then
        cp "$SCRIPT_DIR/../../pkgmgr/ice-pkg" "$SQUASHFS_DIR/usr/local/bin/"
        chmod +x "$SQUASHFS_DIR/usr/local/bin/ice-pkg"
    fi

    # Copy utilities
    if [ -d "$SCRIPT_DIR/../../core" ]; then
        cp -r "$SCRIPT_DIR/../../core/netutils"/* "$SQUASHFS_DIR/usr/local/bin/" 2>/dev/null || true
        cp -r "$SCRIPT_DIR/../../core/sysutils"/* "$SQUASHFS_DIR/usr/local/bin/" 2>/dev/null || true
        chmod +x "$SQUASHFS_DIR/usr/local/bin/"ice* 2>/dev/null || true
    fi

    log "IceNet components installed"
}

# Install live boot components
install_live_components() {
    log "Installing live boot components..."

    # Copy live boot hook
    mkdir -p "$SQUASHFS_DIR/etc/initramfs-tools/hooks"
    if [ -f "$SCRIPT_DIR/../initramfs/live-boot.hook" ]; then
        cp "$SCRIPT_DIR/../initramfs/live-boot.hook" \
            "$SQUASHFS_DIR/etc/initramfs-tools/hooks/live-boot"
        chmod +x "$SQUASHFS_DIR/etc/initramfs-tools/hooks/live-boot"
    fi

    # Copy installer backend
    mkdir -p "$SQUASHFS_DIR/usr/local/lib"
    if [ -f "$SCRIPT_DIR/../installer/installer-backend.sh" ]; then
        cp "$SCRIPT_DIR/../installer/installer-backend.sh" \
            "$SQUASHFS_DIR/usr/local/lib/icenet-installer-backend.sh"
    fi

    # Copy installers (create bin directory first)
    mkdir -p "$SQUASHFS_DIR/usr/local/bin"
    if [ -f "$SCRIPT_DIR/../installer/icenet-installer-gui.py" ]; then
        cp "$SCRIPT_DIR/../installer/icenet-installer-gui.py" \
            "$SQUASHFS_DIR/usr/local/bin/icenet-installer-gui"
        chmod +x "$SQUASHFS_DIR/usr/local/bin/icenet-installer-gui"
    fi

    if [ -f "$SCRIPT_DIR/../installer/icenet-installer-tui.sh" ]; then
        cp "$SCRIPT_DIR/../installer/icenet-installer-tui.sh" \
            "$SQUASHFS_DIR/usr/local/bin/icenet-install"
        chmod +x "$SQUASHFS_DIR/usr/local/bin/icenet-install"
    fi

    # Create desktop entry for GUI installer
    mkdir -p "$SQUASHFS_DIR/usr/share/applications"
    cat > "$SQUASHFS_DIR/usr/share/applications/icenet-installer.desktop" <<EOF
[Desktop Entry]
Name=Install IceNet-OS
Comment=Install IceNet-OS to hard drive
Exec=pkexec icenet-installer-gui
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;
EOF

    log "Live boot components installed"
}

# Install minimal base (LXDE + Edge + SSH/RDP + Software Center)
install_minimal_base() {
    log "Installing minimal base system..."

    if [ -f "$SCRIPT_DIR/install-minimal-base.sh" ]; then
        bash "$SCRIPT_DIR/install-minimal-base.sh" \
            "$SQUASHFS_DIR" \
            "$SCRIPT_DIR/../../integrations"
    else
        warning "Minimal base installer not found, skipping"
    fi

    log "Minimal base installed"
}

# Create squashfs
create_squashfs() {
    log "Creating squashfs filesystem (this may take several minutes)..."

    # Update initramfs
    if [ -f "$SQUASHFS_DIR/usr/sbin/update-initramfs" ]; then
        if ! chroot "$SQUASHFS_DIR" update-initramfs -u 2>&1; then
            warning "Failed to update initramfs (non-critical, continuing)"
        fi
    fi

    # Create squashfs with compression based on build mode
    if [ "$FAST_COMPRESSION" = "true" ]; then
        log "Using FAST compression (gzip) - larger ISO but 3x faster"
        mksquashfs "$SQUASHFS_DIR" "$ISO_DIR/live/filesystem.squashfs" \
            -comp gzip \
            -b 1M \
            -noappend \
            -progress
    else
        log "Using BEST compression (xz) - smaller ISO but slower"
        mksquashfs "$SQUASHFS_DIR" "$ISO_DIR/live/filesystem.squashfs" \
            -comp xz \
            -b 1M \
            -Xdict-size 100% \
            -noappend \
            -progress
    fi

    log "Squashfs created: $(du -h "$ISO_DIR/live/filesystem.squashfs" | cut -f1)"
}

# Copy kernel and initrd
copy_kernel() {
    log "Copying kernel and initrd..."

    # Find kernel
    KERNEL=$(find "$SQUASHFS_DIR/boot" -name "vmlinuz-*" | sort -V | tail -n1)
    INITRD=$(find "$SQUASHFS_DIR/boot" -name "initrd.img-*" | sort -V | tail -n1)

    if [ -z "$KERNEL" ]; then
        error "No kernel found in squashfs"
    fi

    if [ -z "$INITRD" ]; then
        error "No initrd found in squashfs. Try running: chroot $SQUASHFS_DIR update-initramfs -c -k all"
    fi

    cp "$KERNEL" "$ISO_DIR/live/vmlinuz"
    cp "$INITRD" "$ISO_DIR/live/initrd.img"

    log "Kernel and initrd copied"
}

# Create GRUB configuration
create_grub_config() {
    log "Creating GRUB configuration..."

    cat > "$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set default="0"
set timeout=10

menuentry "IceNet-OS Live" {
    linux /live/vmlinuz boot=live icenet-live quiet splash
    initrd /live/initrd.img
}

menuentry "IceNet-OS Live (Persistence)" {
    linux /live/vmlinuz boot=live icenet-live persistence quiet splash
    initrd /live/initrd.img
}

menuentry "IceNet-OS Live (Load to RAM)" {
    linux /live/vmlinuz boot=live icenet-live toram quiet splash
    initrd /live/initrd.img
}

menuentry "Install IceNet-OS" {
    linux /live/vmlinuz boot=live icenet-live quiet splash
    initrd /live/initrd.img
}

menuentry "IceNet-OS Live (Debug)" {
    linux /live/vmlinuz boot=live icenet-live debug
    initrd /live/initrd.img
}

menuentry "Boot from first hard disk" {
    set root=(hd0)
    chainloader +1
}
EOF

    log "GRUB configuration created"
}

# Build ISO
build_iso() {
    log "Building ISO image..."

    # Let grub-mkrescue handle hybrid boot automatically
    grub-mkrescue -o "$OUTPUT_DIR/$ISO_NAME" "$ISO_DIR" \
        -volid "ICENET-OS"

    log "ISO created: $OUTPUT_DIR/$ISO_NAME"
    log "Size: $(du -h $OUTPUT_DIR/$ISO_NAME | cut -f1)"
}

# Create checksum
create_checksum() {
    log "Creating checksums..."

    cd "$OUTPUT_DIR"
    sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
    md5sum "$ISO_NAME" > "$ISO_NAME.md5"

    log "Checksums created"
}

# Main build process
main() {
    log "===== IceNet-OS ISO Builder ====="

    check_requirements
    clean_build
    build_base_system
    setup_default_user
    install_icenet_components
    install_live_components
    install_minimal_base
    create_squashfs
    copy_kernel
    create_grub_config
    build_iso
    create_checksum

    log "===== Build Complete ====="
    log "ISO location: $OUTPUT_DIR/$ISO_NAME"
    log ""
    log "To write to USB:"
    log "  sudo dd if=$OUTPUT_DIR/$ISO_NAME of=/dev/sdX bs=4M status=progress"
    log ""
    log "To test in QEMU:"
    log "  qemu-system-x86_64 -m 2G -cdrom $OUTPUT_DIR/$ISO_NAME -boot d"
}

main "$@"
