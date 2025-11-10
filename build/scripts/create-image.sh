#!/bin/bash
# IceNet-OS Bootable Image Creator
#
# Creates bootable disk images for IceNet-OS

set -e

ARCH=${1:-x86_64}
BUILD_DIR=${2:-../build-output}
VERSION="0.1.0"

echo "Creating bootable image for $ARCH..."

IMAGE_NAME="icenet-os-$ARCH-$VERSION.img"
IMAGE_PATH="$BUILD_DIR/$IMAGE_NAME"
MOUNT_DIR="$BUILD_DIR/mnt"

case "$ARCH" in
    x86_64)
        create_x86_64_image
        ;;
    aarch64)
        create_arm64_image
        ;;
    armv7)
        create_armv7_image
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Image created: $IMAGE_PATH"

function create_x86_64_image() {
    echo "Creating x86_64 disk image..."

    # Create a 2GB image
    dd if=/dev/zero of="$IMAGE_PATH" bs=1M count=2048 status=progress

    # Create partition table
    parted -s "$IMAGE_PATH" mklabel msdos
    parted -s "$IMAGE_PATH" mkpart primary ext4 1MiB 100%
    parted -s "$IMAGE_PATH" set 1 boot on

    # Setup loop device
    LOOP_DEV=$(losetup -f)
    losetup "$LOOP_DEV" "$IMAGE_PATH"
    partprobe "$LOOP_DEV"

    # Format partition
    mkfs.ext4 -L "ICENET-ROOT" "${LOOP_DEV}p1"

    # Mount and populate
    mkdir -p "$MOUNT_DIR"
    mount "${LOOP_DEV}p1" "$MOUNT_DIR"

    # Copy rootfs
    rsync -a "$BUILD_DIR/rootfs/" "$MOUNT_DIR/"

    # Install bootloader (GRUB)
    install_grub_x86_64 "$LOOP_DEV" "$MOUNT_DIR"

    # Cleanup
    umount "$MOUNT_DIR"
    losetup -d "$LOOP_DEV"

    echo "x86_64 image created successfully"
}

function install_grub_x86_64() {
    local device=$1
    local mount=$2

    echo "Installing GRUB bootloader..."

    mkdir -p "$mount/boot/grub"

    # Create GRUB configuration
    cat > "$mount/boot/grub/grub.cfg" << 'EOF'
set timeout=3
set default=0

menuentry "IceNet-OS" {
    linux /boot/vmlinuz root=/dev/sda1 rw quiet
    initrd /boot/initrd.img
}

menuentry "IceNet-OS (Recovery)" {
    linux /boot/vmlinuz root=/dev/sda1 rw single
    initrd /boot/initrd.img
}
EOF

    # Install GRUB (if available)
    if command -v grub-install >/dev/null 2>&1; then
        grub-install --target=i386-pc --boot-directory="$mount/boot" "$device" || true
    else
        echo "Warning: grub-install not available, bootloader not installed"
    fi
}

function create_arm64_image() {
    echo "Creating ARM64 (Raspberry Pi) disk image..."

    # Create a 2GB image
    dd if=/dev/zero of="$IMAGE_PATH" bs=1M count=2048 status=progress

    # Create partition table (MBR for Raspberry Pi compatibility)
    parted -s "$IMAGE_PATH" mklabel msdos
    parted -s "$IMAGE_PATH" mkpart primary fat32 1MiB 257MiB
    parted -s "$IMAGE_PATH" set 1 boot on
    parted -s "$IMAGE_PATH" mkpart primary ext4 257MiB 100%

    # Setup loop device
    LOOP_DEV=$(losetup -f)
    losetup "$LOOP_DEV" "$IMAGE_PATH"
    partprobe "$LOOP_DEV"

    # Format partitions
    mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1"
    mkfs.ext4 -L "ICENET-ROOT" "${LOOP_DEV}p2"

    # Mount and populate
    mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/root"
    mount "${LOOP_DEV}p1" "$MOUNT_DIR/boot"
    mount "${LOOP_DEV}p2" "$MOUNT_DIR/root"

    # Copy rootfs
    rsync -a "$BUILD_DIR/rootfs/" "$MOUNT_DIR/root/"

    # Setup boot partition for Raspberry Pi
    setup_rpi_boot "$MOUNT_DIR/boot"

    # Cleanup
    umount "$MOUNT_DIR/boot"
    umount "$MOUNT_DIR/root"
    losetup -d "$LOOP_DEV"

    echo "ARM64 image created successfully"
}

function setup_rpi_boot() {
    local boot_dir=$1

    echo "Setting up Raspberry Pi boot partition..."

    # Create config.txt
    cat > "$boot_dir/config.txt" << 'EOF'
# IceNet-OS Raspberry Pi Configuration

# Enable 64-bit mode
arm_64bit=1

# GPU memory
gpu_mem=64

# Enable UART
enable_uart=1

# Disable splash screen
disable_splash=1

# Overclock (conservative)
over_voltage=0
arm_freq=1500
EOF

    # Create cmdline.txt
    cat > "$boot_dir/cmdline.txt" << 'EOF'
console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet init=/sbin/icenet-init
EOF

    echo "Raspberry Pi boot configuration created"
}

function create_armv7_image() {
    echo "Creating ARMv7 (32-bit Raspberry Pi) disk image..."

    # Similar to ARM64 but with 32-bit kernel
    create_arm64_image

    # Modify config.txt to disable 64-bit mode
    sed -i 's/arm_64bit=1/arm_64bit=0/' "$MOUNT_DIR/boot/config.txt"
}
