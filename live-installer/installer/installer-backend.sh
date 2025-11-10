#!/bin/bash
# IceNet-OS Installer Backend
# Core installation logic for both GUI and TUI installers

set -e

# Configuration
INSTALLER_LOG="/tmp/icenet-install.log"
MOUNT_POINT="/mnt/icenet-install"
SQUASHFS_SOURCE="/live/media/live/filesystem.squashfs"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$INSTALLER_LOG"
}

error() {
    echo "[ERROR] $*" | tee -a "$INSTALLER_LOG" >&2
    return 1
}

# Progress reporting (for GUI)
report_progress() {
    local percent=$1
    local message=$2
    echo "PROGRESS:$percent:$message"
}

# Detect available disks
detect_disks() {
    log "Detecting available disks"
    lsblk -ndo NAME,SIZE,TYPE | grep disk | while read -r disk size _; do
        # Skip loop devices and live media
        if [[ ! "$disk" =~ loop ]] && [ "$disk" != "$(basename $LIVE_DEVICE)" ]; then
            echo "/dev/$disk:$size"
        fi
    done
}

# Partition disk (automatic)
partition_disk_auto() {
    local disk=$1
    local use_encryption=${2:-no}

    log "Auto-partitioning $disk"
    report_progress 10 "Partitioning disk..."

    # Detect if UEFI or BIOS
    if [ -d /sys/firmware/efi ]; then
        BOOT_MODE="UEFI"
    else
        BOOT_MODE="BIOS"
    fi

    # Wipe existing partition table
    wipefs -af "$disk"
    sgdisk --zap-all "$disk"

    if [ "$BOOT_MODE" = "UEFI" ]; then
        log "Creating GPT partitions for UEFI"
        # EFI partition (512MB)
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$disk"
        # Root partition (remaining space)
        sgdisk -n 2:0:0 -t 2:8300 -c 2:"IceNet Root" "$disk"

        # Get partition names
        if [[ "$disk" =~ nvme ]]; then
            BOOT_PART="${disk}p1"
            ROOT_PART="${disk}p2"
        else
            BOOT_PART="${disk}1"
            ROOT_PART="${disk}2"
        fi
    else
        log "Creating MBR partitions for BIOS"
        # Boot partition (1GB)
        sgdisk -n 1:0:+1G -t 1:8300 -c 1:"Boot" "$disk"
        # Root partition (remaining)
        sgdisk -n 2:0:0 -t 2:8300 -c 2:"IceNet Root" "$disk"

        if [[ "$disk" =~ nvme ]]; then
            BOOT_PART="${disk}p1"
            ROOT_PART="${disk}p2"
        else
            BOOT_PART="${disk}1"
            ROOT_PART="${disk}2"
        fi
    fi

    # Inform kernel of partition changes
    partprobe "$disk"
    sleep 2

    log "Partitioning complete: BOOT=$BOOT_PART ROOT=$ROOT_PART"
    export BOOT_PART ROOT_PART BOOT_MODE
}

# Create filesystems
create_filesystems() {
    report_progress 20 "Creating filesystems..."

    log "Creating filesystems"

    if [ "$BOOT_MODE" = "UEFI" ]; then
        log "Formatting EFI partition as FAT32"
        mkfs.vfat -F 32 -n ICENET-EFI "$BOOT_PART"
    else
        log "Formatting boot partition as ext4"
        mkfs.ext4 -F -L icenet-boot "$BOOT_PART"
    fi

    log "Formatting root partition as ext4"
    mkfs.ext4 -F -L icenet-root "$ROOT_PART"

    log "Filesystems created"
}

# Mount filesystems
mount_filesystems() {
    report_progress 25 "Mounting filesystems..."

    log "Mounting filesystems"

    mkdir -p "$MOUNT_POINT"
    mount "$ROOT_PART" "$MOUNT_POINT"

    mkdir -p "$MOUNT_POINT/boot"
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkdir -p "$MOUNT_POINT/boot/efi"
        mount "$BOOT_PART" "$MOUNT_POINT/boot/efi"
    else
        mount "$BOOT_PART" "$MOUNT_POINT/boot"
    fi

    log "Filesystems mounted at $MOUNT_POINT"
}

# Copy system files
copy_system() {
    report_progress 30 "Copying system files (this may take several minutes)..."

    log "Copying system from $SQUASHFS_SOURCE"

    # Mount squashfs if not already mounted
    if [ ! -d /live/rootfs ]; then
        mkdir -p /live/rootfs
        mount -t squashfs -o ro,loop "$SQUASHFS_SOURCE" /live/rootfs
    fi

    # Copy all files with rsync
    rsync -aAXv /live/rootfs/ "$MOUNT_POINT/" \
        --exclude=/proc/* \
        --exclude=/sys/* \
        --exclude=/dev/* \
        --exclude=/tmp/* \
        --exclude=/run/* \
        --exclude=/mnt/* \
        --exclude=/media/* \
        --exclude=/live/* \
        --exclude=/swapfile \
        --info=progress2 2>&1 | while read line; do
        if [[ "$line" =~ ([0-9]+)% ]]; then
            percent=$((30 + ${BASH_REMATCH[1]} * 40 / 100))
            report_progress $percent "Copying system files: ${BASH_REMATCH[1]}%"
        fi
    done

    log "System files copied"
    report_progress 70 "System files copied"
}

# Configure system
configure_system() {
    local hostname=$1
    local username=$2
    local password=$3
    local timezone=$4
    local locale=${5:-en_US.UTF-8}

    report_progress 75 "Configuring system..."

    log "Configuring system"

    # Mount special filesystems
    mount --bind /dev "$MOUNT_POINT/dev"
    mount --bind /dev/pts "$MOUNT_POINT/dev/pts"
    mount --bind /proc "$MOUNT_POINT/proc"
    mount --bind /sys "$MOUNT_POINT/sys"

    # Create fstab
    log "Creating fstab"
    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
    BOOT_UUID=$(blkid -s UUID -o value "$BOOT_PART")

    cat > "$MOUNT_POINT/etc/fstab" <<EOF
# IceNet-OS fstab
UUID=$ROOT_UUID  /          ext4    errors=remount-ro  0  1
EOF

    if [ "$BOOT_MODE" = "UEFI" ]; then
        echo "UUID=$BOOT_UUID  /boot/efi  vfat    umask=0077         0  2" >> "$MOUNT_POINT/etc/fstab"
    else
        echo "UUID=$BOOT_UUID  /boot      ext4    defaults           0  2" >> "$MOUNT_POINT/etc/fstab"
    fi

    # Set hostname
    log "Setting hostname: $hostname"
    echo "$hostname" > "$MOUNT_POINT/etc/hostname"

    cat > "$MOUNT_POINT/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   $hostname

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

    # Set timezone
    log "Setting timezone: $timezone"
    chroot "$MOUNT_POINT" ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime

    # Set locale
    log "Setting locale: $locale"
    echo "$locale UTF-8" > "$MOUNT_POINT/etc/locale.gen"
    echo "LANG=$locale" > "$MOUNT_POINT/etc/locale.conf"
    chroot "$MOUNT_POINT" locale-gen 2>/dev/null || true

    # Create user
    log "Creating user: $username"
    chroot "$MOUNT_POINT" useradd -m -G wheel,audio,video,network,storage -s /bin/bash "$username"
    echo "$username:$password" | chroot "$MOUNT_POINT" chpasswd

    # Set root password
    echo "root:$password" | chroot "$MOUNT_POINT" chpasswd

    # Remove live boot marker
    rm -f "$MOUNT_POINT/run/icenet/live-boot" 2>/dev/null || true

    log "System configured"
    report_progress 80 "System configured"
}

# Install bootloader
install_bootloader() {
    local disk=$1

    report_progress 85 "Installing bootloader..."

    log "Installing bootloader to $disk"

    if [ "$BOOT_MODE" = "UEFI" ]; then
        log "Installing GRUB for UEFI"
        chroot "$MOUNT_POINT" grub-install \
            --target=x86_64-efi \
            --efi-directory=/boot/efi \
            --bootloader-id=IceNet \
            --recheck

        # Create EFI entry
        chroot "$MOUNT_POINT" efibootmgr --create \
            --disk "$disk" \
            --part 1 \
            --label "IceNet-OS" \
            --loader '\EFI\IceNet\grubx64.efi' 2>/dev/null || true
    else
        log "Installing GRUB for BIOS"
        chroot "$MOUNT_POINT" grub-install \
            --target=i386-pc \
            --recheck \
            "$disk"
    fi

    # Generate GRUB configuration
    log "Generating GRUB configuration"
    chroot "$MOUNT_POINT" grub-mkconfig -o /boot/grub/grub.cfg

    log "Bootloader installed"
    report_progress 95 "Bootloader installed"
}

# Cleanup
cleanup() {
    report_progress 98 "Finalizing installation..."

    log "Cleaning up"

    # Unmount special filesystems
    umount "$MOUNT_POINT/dev/pts" 2>/dev/null || true
    umount "$MOUNT_POINT/dev" 2>/dev/null || true
    umount "$MOUNT_POINT/proc" 2>/dev/null || true
    umount "$MOUNT_POINT/sys" 2>/dev/null || true

    # Unmount boot and root
    if [ "$BOOT_MODE" = "UEFI" ]; then
        umount "$MOUNT_POINT/boot/efi" 2>/dev/null || true
    else
        umount "$MOUNT_POINT/boot" 2>/dev/null || true
    fi
    umount "$MOUNT_POINT" 2>/dev/null || true

    log "Cleanup complete"
    report_progress 100 "Installation complete!"
}

# Full installation
full_install() {
    local disk=$1
    local hostname=$2
    local username=$3
    local password=$4
    local timezone=$5
    local locale=$6

    log "=== Starting IceNet-OS Installation ==="
    log "Target disk: $disk"
    log "Hostname: $hostname"
    log "Username: $username"
    log "Timezone: $timezone"

    trap cleanup EXIT

    partition_disk_auto "$disk"
    create_filesystems
    mount_filesystems
    copy_system
    configure_system "$hostname" "$username" "$password" "$timezone" "$locale"
    install_bootloader "$disk"
    cleanup

    log "=== Installation Complete ==="
    log "Installation log saved to: $INSTALLER_LOG"

    return 0
}

# Export functions for use by GUI/TUI
export -f log error report_progress
export -f detect_disks partition_disk_auto create_filesystems
export -f mount_filesystems copy_system configure_system
export -f install_bootloader cleanup full_install
