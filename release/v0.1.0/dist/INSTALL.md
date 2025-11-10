# IceNet-OS v0.1 Installation Guide

## Quick Start

### Option 1: Build Live ISO (Recommended)

For a complete bootable system:

```bash
# For x86_64 (Zima boards)
cd live-installer/iso-builder
sudo ./build-iso.sh

# Write to USB
sudo dd if=output/icenet-os-*.iso of=/dev/sdX bs=4M status=progress
```

```bash
# For ARM (Raspberry Pi)
cd live-installer/iso-builder
sudo ./build-arm-image.sh

# Write to SD card
sudo dd if=output/icenet-os-arm-*.img of=/dev/sdX bs=4M status=progress
```

### Option 2: Manual Installation

1. Install base system (Debian/Ubuntu)
2. Copy binaries to /usr/local/bin:
   ```bash
   sudo cp bin/* /usr/local/bin/
   sudo chmod +x /usr/local/bin/ice*
   ```

3. Install integrations:
   ```bash
   cd integrations
   sudo ./install-integrations.sh
   ```

## Components

- **bin/** - Compiled binaries (init, package manager, utilities)
- **integrations/** - Optional software packages
- **live-installer/** - ISO/image builders
- **etc/** - Configuration files
- **doc/** - Documentation

## Requirements

### For ISO Building
- debootstrap
- squashfs-tools
- grub-pc-bin (x86_64)
- grub-efi-amd64-bin (x86_64)
- xorriso
- qemu-user-static (ARM)

Install on Debian/Ubuntu:
```bash
sudo apt-get install debootstrap squashfs-tools grub-pc-bin \
  grub-efi-amd64-bin xorriso qemu-user-static
```

## Next Steps

1. Read README.md for overview
2. See live-installer/QUICKSTART.md for live USB guide
3. Explore integrations for mesh networking and SDR

## Support

For issues and documentation: doc/
