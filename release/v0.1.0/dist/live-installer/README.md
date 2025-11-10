# IceNet-OS Live USB & Installer

Complete live USB boot system with graphical and text-based installer, similar to Linux Mint.

## Features

- **Live Mode**: Run IceNet-OS directly from USB without installation
- **Persistence**: Optional persistent storage on USB for saving changes
- **Dual Installer**: Both GUI and TUI installers available
- **Full Installation**: Install to internal disk with automatic partitioning
- **Multi-Architecture**: Works on both x86_64 (Zima boards) and ARM (Raspberry Pi)

## Quick Start

### Creating a Live USB

```bash
# Build the ISO image
cd live-installer/iso-builder
sudo ./build-iso.sh

# Write to USB drive (replace /dev/sdX with your USB device)
sudo dd if=icenet-os.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

### Raspberry Pi SD Card

```bash
# Build ARM image
cd live-installer/iso-builder
sudo ./build-arm-image.sh

# Write to SD card
sudo dd if=icenet-os-arm.img of=/dev/sdX bs=4M status=progress
sudo sync
```

## Boot Options

When booting from USB/SD card, you'll see:

1. **Live Mode** - Run without installing (default after 10s)
2. **Live Mode with Persistence** - Save changes to USB
3. **Install to Disk** - Launch installer
4. **Boot from Local Disk** - Boot installed OS

## Installation Options

### GUI Installer (Desktop Environment)

The graphical installer provides:
- Visual disk partitioning
- User account creation
- Timezone and locale selection
- Installation progress tracking
- Automatic GRUB installation

Launch from desktop: `IceNet Installer` icon

### TUI Installer (Text Mode)

Text-based installer for headless or minimal installations:
- Full keyboard navigation
- Same features as GUI
- Works over serial console
- Lower memory requirements

Launch from terminal: `sudo icenet-install`

## Architecture

### Live Boot Process

1. **GRUB/U-Boot** loads kernel and initramfs
2. **Initramfs** detects live mode, mounts squashfs
3. **Overlay filesystem** provides read-write layer
4. **Init system** starts normally with live services
5. **Desktop/Shell** launches with installer option

### Persistence

Optional persistence partition on USB stores:
- User home directories
- System configuration changes
- Installed packages
- Application data

### Installation Process

1. **Disk Detection** - Scans available disks
2. **Partitioning** - Auto or manual partition setup
3. **Filesystem Creation** - Creates ext4, swap, EFI partitions
4. **System Copy** - Extracts system from squashfs
5. **Bootloader** - Installs GRUB (x86) or U-Boot (ARM)
6. **Configuration** - Sets up fstab, hostname, users
7. **Finalization** - Installs kernel, updates initramfs

## Components

### initramfs/
Live boot initramfs hooks and scripts for overlay filesystem mounting

### installer/
- `icenet-installer-gui.py` - GTK-based graphical installer
- `icenet-installer-tui.py` - Curses-based text installer
- `installer-backend.sh` - Core installation logic
- `partition-manager.sh` - Disk partitioning utilities

### iso-builder/
- `build-iso.sh` - x86_64 ISO generation
- `build-arm-image.sh` - ARM image generation
- `squashfs-config/` - Live system configuration

### boot-menu/
- `grub.cfg` - x86_64 GRUB configuration
- `boot.txt` - ARM U-Boot configuration

## System Requirements

### Live Mode
- 2GB RAM minimum (4GB recommended)
- 8GB+ USB drive
- x86_64 CPU with 64-bit support, or ARM Cortex-A53+

### Installation
- 16GB+ disk space
- Same CPU requirements as live mode
- Network connection (recommended for updates)

## Advanced Usage

### Custom ISO

Edit `iso-builder/squashfs-config/customize.sh` to:
- Pre-install packages
- Configure default settings
- Add custom files
- Modify desktop appearance

### Automated Installation

Create `icenet-install.conf` on USB root for unattended installation:

```bash
# Auto-install configuration
INSTALL_DISK=/dev/sda
HOSTNAME=icenet-node
USERNAME=icenet
PASSWORD_HASH='$6$...'
TIMEZONE=America/New_York
LOCALE=en_US.UTF-8
AUTO_REBOOT=yes
```

### Network Installation

Boot with `netinstall` parameter to install directly from repositories instead of local squashfs.

## Troubleshooting

### Boot Issues

**"Kernel panic - not syncing"**
- Initramfs may be corrupted, rebuild ISO
- Try `icenet-live debug` boot option

**"Failed to mount overlay"**
- USB drive may be failing
- Boot with `toram` to load entire system to RAM

### Installation Issues

**"No suitable disk found"**
- Check disk is detected: `lsblk`
- May need different kernel driver

**"Bootloader installation failed"**
- For UEFI: Ensure EFI partition exists
- For Legacy: Check GRUB can access /boot

## Files

- `live-boot.hook` - Initramfs hook for live boot
- `icenet-installer-gui.py` - GTK3 graphical installer
- `icenet-installer-tui.py` - Ncurses text installer
- `installer-backend.sh` - Installation automation
- `build-iso.sh` - ISO image builder
- `build-arm-image.sh` - ARM image builder

## License

MIT License - Same as IceNet-OS
