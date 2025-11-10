#!/bin/bash
# IceNet-OS ARM Image Builder
# Builds bootable SD card image for Raspberry Pi

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/icenet-arm-build"
OUTPUT_DIR="$SCRIPT_DIR/output"
IMAGE_NAME="icenet-os-arm-$(date +%Y%m%d).img"
IMAGE_SIZE="4G"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
    command -v parted >/dev/null || missing+=("parted")
    command -v qemu-arm-static >/dev/null || missing+=("qemu-user-static")

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
    mkdir -p "$BUILD_DIR"/{boot,root,squashfs}
    mkdir -p "$OUTPUT_DIR"
}

# Create image file
create_image() {
    log "Creating image file..."

    # Create empty image
    dd if=/dev/zero of="$OUTPUT_DIR/$IMAGE_NAME" bs=1 count=0 seek=$IMAGE_SIZE

    # Setup loop device
    LOOP_DEV=$(losetup -f)
    losetup "$LOOP_DEV" "$OUTPUT_DIR/$IMAGE_NAME"

    # Partition the image
    parted -s "$LOOP_DEV" mklabel msdos
    parted -s "$LOOP_DEV" mkpart primary fat32 1MiB 256MiB
    parted -s "$LOOP_DEV" mkpart primary ext4 256MiB 100%

    # Inform kernel
    partprobe "$LOOP_DEV"
    sleep 2

    # Get partition devices
    BOOT_PART="${LOOP_DEV}p1"
    ROOT_PART="${LOOP_DEV}p2"

    # Format partitions
    mkfs.vfat -F 32 -n ICENET-BOOT "$BOOT_PART"
    mkfs.ext4 -F -L icenet-root "$ROOT_PART"

    log "Image partitioned"
}

# Build base system
build_base_system() {
    log "Building ARM base system..."

    # Mount root partition
    mount "$ROOT_PART" "$BUILD_DIR/root"

    # Bootstrap ARM system
    debootstrap --arch=arm64 --variant=minbase \
        --foreign \
        bookworm "$BUILD_DIR/root" \
        http://deb.debian.org/debian/

    # Copy qemu for second stage
    cp /usr/bin/qemu-aarch64-static "$BUILD_DIR/root/usr/bin/"

    # Second stage
    chroot "$BUILD_DIR/root" /debootstrap/debootstrap --second-stage

    # Install essential packages
    chroot "$BUILD_DIR/root" apt-get update
    chroot "$BUILD_DIR/root" apt-get install -y \
        linux-image-arm64 \
        firmware-brcm80211 \
        raspi-firmware \
        network-manager \
        sudo \
        dialog \
        python3 \
        python3-gi \
        gir1.2-gtk-3.0 \
        u-boot-tools

    log "Base system built"
}

# Install IceNet components
install_icenet_components() {
    log "Installing IceNet components..."

    # Same as x86_64 but for ARM
    if [ -f "$SCRIPT_DIR/../../init/icenet-init" ]; then
        cp "$SCRIPT_DIR/../../init/icenet-init" "$BUILD_DIR/root/sbin/"
        chmod +x "$BUILD_DIR/root/sbin/icenet-init"
    fi

    if [ -f "$SCRIPT_DIR/../../pkgmgr/ice-pkg" ]; then
        cp "$SCRIPT_DIR/../../pkgmgr/ice-pkg" "$BUILD_DIR/root/usr/local/bin/"
        chmod +x "$BUILD_DIR/root/usr/local/bin/ice-pkg"
    fi

    # Copy utilities
    if [ -d "$SCRIPT_DIR/../../core" ]; then
        cp -r "$SCRIPT_DIR/../../core/netutils"/* "$BUILD_DIR/root/usr/local/bin/" 2>/dev/null || true
        cp -r "$SCRIPT_DIR/../../core/sysutils"/* "$BUILD_DIR/root/usr/local/bin/" 2>/dev/null || true
        chmod +x "$BUILD_DIR/root/usr/local/bin/"ice* 2>/dev/null || true
    fi

    log "IceNet components installed"
}

# Install live boot components
install_live_components() {
    log "Installing live boot components..."

    # Copy installer backend
    mkdir -p "$BUILD_DIR/root/usr/local/lib"
    if [ -f "$SCRIPT_DIR/../installer/installer-backend.sh" ]; then
        cp "$SCRIPT_DIR/../installer/installer-backend.sh" \
            "$BUILD_DIR/root/usr/local/lib/icenet-installer-backend.sh"
    fi

    # Copy installers
    if [ -f "$SCRIPT_DIR/../installer/icenet-installer-gui.py" ]; then
        cp "$SCRIPT_DIR/../installer/icenet-installer-gui.py" \
            "$BUILD_DIR/root/usr/local/bin/icenet-installer-gui"
        chmod +x "$BUILD_DIR/root/usr/local/bin/icenet-installer-gui"
    fi

    if [ -f "$SCRIPT_DIR/../installer/icenet-installer-tui.sh" ]; then
        cp "$SCRIPT_DIR/../installer/icenet-installer-tui.sh" \
            "$BUILD_DIR/root/usr/local/bin/icenet-install"
        chmod +x "$BUILD_DIR/root/usr/local/bin/icenet-install"
    fi

    # Mark as live boot
    mkdir -p "$BUILD_DIR/root/run/icenet"
    touch "$BUILD_DIR/root/run/icenet/live-boot"

    log "Live boot components installed"
}

# Configure system
configure_system() {
    log "Configuring system..."

    # Enable serial console
    cat >> "$BUILD_DIR/root/etc/inittab" <<EOF
T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100
EOF

    # Set hostname
    echo "icenet-live" > "$BUILD_DIR/root/etc/hostname"

    # Configure fstab
    cat > "$BUILD_DIR/root/etc/fstab" <<EOF
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1
EOF

    # Enable networking
    cat > "$BUILD_DIR/root/etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

    log "System configured"
}

# Setup boot partition
setup_boot() {
    log "Setting up boot partition..."

    # Mount boot partition
    mount "$BOOT_PART" "$BUILD_DIR/boot"

    # Copy kernel and initrd
    KERNEL=$(find "$BUILD_DIR/root/boot" -name "vmlinuz-*" | sort -V | tail -n1)
    INITRD=$(find "$BUILD_DIR/root/boot" -name "initrd.img-*" | sort -V | tail -n1)

    if [ -n "$KERNEL" ]; then
        cp "$KERNEL" "$BUILD_DIR/boot/kernel8.img"
    fi

    if [ -n "$INITRD" ]; then
        cp "$INITRD" "$BUILD_DIR/boot/initrd8.img"
    fi

    # Create boot configuration
    cat > "$BUILD_DIR/boot/config.txt" <<EOF
# IceNet-OS Boot Configuration
arm_64bit=1
kernel=kernel8.img
initramfs initrd8.img followkernel

# Hardware
gpu_mem=64
dtparam=audio=on
dtparam=i2c_arm=on
dtparam=spi=on

# Display
hdmi_force_hotplug=1
EOF

    # Create cmdline
    cat > "$BUILD_DIR/boot/cmdline.txt" <<EOF
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet splash
EOF

    umount "$BUILD_DIR/boot"

    log "Boot partition configured"
}

# Cleanup
cleanup() {
    log "Cleaning up..."

    # Unmount everything
    umount "$BUILD_DIR/root" 2>/dev/null || true
    umount "$BUILD_DIR/boot" 2>/dev/null || true

    # Detach loop device
    if [ -n "$LOOP_DEV" ]; then
        losetup -d "$LOOP_DEV"
    fi

    log "Cleanup complete"
}

# Main build process
main() {
    log "===== IceNet-OS ARM Image Builder ====="

    trap cleanup EXIT

    check_requirements
    clean_build
    create_image
    build_base_system
    install_icenet_components
    install_live_components
    configure_system
    setup_boot

    log "===== Build Complete ====="
    log "Image location: $OUTPUT_DIR/$IMAGE_NAME"
    log ""
    log "To write to SD card:"
    log "  sudo dd if=$OUTPUT_DIR/$IMAGE_NAME of=/dev/sdX bs=4M status=progress"
    log "  sudo sync"
    log ""
    log "Insert SD card into Raspberry Pi and boot!"
}

main "$@"
