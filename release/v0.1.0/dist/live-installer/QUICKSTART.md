# IceNet-OS Live USB Quick Start

## For x86_64 (Zima Boards)

### 1. Build the ISO

```bash
cd live-installer/iso-builder
sudo ./build-iso.sh
```

This creates: `output/icenet-os-YYYYMMDD.iso`

### 2. Write to USB Drive

**Linux:**
```bash
sudo dd if=output/icenet-os-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

**Windows:**
Use [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/)

**macOS:**
```bash
sudo dd if=output/icenet-os-*.iso of=/dev/rdiskX bs=4m
```

⚠️ Replace `/dev/sdX` with your USB device (check with `lsblk`)

### 3. Boot from USB

1. Insert USB drive
2. Reboot computer
3. Enter BIOS/UEFI (usually F2, F12, DEL, or ESC)
4. Select USB drive as boot device
5. Choose boot option from menu

## For Raspberry Pi

### 1. Build the ARM Image

```bash
cd live-installer/iso-builder
sudo ./build-arm-image.sh
```

This creates: `output/icenet-os-arm-YYYYMMDD.img`

### 2. Write to SD Card

**Linux:**
```bash
sudo dd if=output/icenet-os-arm-*.img of=/dev/sdX bs=4M status=progress conv=fsync
sudo sync
```

**Windows/macOS:**
Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

### 3. Boot Raspberry Pi

1. Insert SD card
2. Connect HDMI, keyboard, power
3. Pi boots automatically

## Boot Menu Options

### Live Mode
Run IceNet-OS from USB/SD without installation
- Changes lost on reboot
- Fastest boot option
- Perfect for testing

### Live Mode (Persistence)
Run from USB/SD but save changes
- Requires persistence partition
- Changes persist across reboots
- Good for portable system

### Live Mode (Load to RAM)
Copy entire system to RAM
- Can remove USB after boot
- Fastest performance
- Requires 4GB+ RAM

### Install to Disk
Launch installer to copy IceNet-OS to internal drive
- Permanent installation
- Optimal performance
- GUI or text-based installer

## Installation Process

### Graphical Installer

1. Boot to Live Mode
2. Click "Install IceNet-OS" icon on desktop
3. Follow wizard:
   - Select target disk
   - Create user account
   - Configure timezone
   - Confirm and install
4. Reboot when complete

### Text Installer

1. Boot to Live Mode
2. Open terminal
3. Run: `sudo icenet-install`
4. Follow prompts
5. Reboot when complete

## Creating Persistence Partition

For live USB with persistence:

```bash
# Identify USB device (e.g., /dev/sdb)
lsblk

# Create persistence partition (4GB recommended)
sudo parted /dev/sdX mkpart primary ext4 2GB 6GB
sudo mkfs.ext4 -L icenet-persist /dev/sdX3

# Mount and configure
sudo mount /dev/sdX3 /mnt
sudo mkdir -p /mnt/upper /mnt/work
sudo umount /mnt
```

Now boot with "Live Mode (with Persistence)" option.

## Troubleshooting

### Won't Boot
- Verify BIOS boot mode (UEFI vs Legacy)
- Try "Safe Mode" boot option
- Check USB drive integrity with checksum

### No Display
- Try "Safe Mode" (disables graphics acceleration)
- Check HDMI cable and monitor input
- For Pi: ensure config.txt is correct

### Installer Crashes
- Use text installer: `sudo icenet-install`
- Check logs: `/tmp/icenet-install.log`
- Ensure 2GB+ RAM available

### Network Not Working
- Check driver support: `lsmod | grep -i network`
- Try: `sudo systemctl restart NetworkManager`
- For Pi: ensure firmware-brcm80211 installed

## System Requirements

### Minimum (Live Mode)
- 2GB RAM
- 8GB USB drive/SD card
- x86_64 CPU or ARM Cortex-A53+

### Recommended (Installation)
- 4GB+ RAM
- 32GB+ storage
- x86_64 with 64-bit support
- Network connection

## After Installation

### First Boot
1. Login with created username
2. Run system update: `sudo ice-pkg update`
3. Install additional software: `cd integrations && sudo ./install-integrations.sh`
4. Configure network and services

### Desktop Environment
If installed, start GUI:
```bash
sudo systemctl start lightdm
```

Or enable automatic start:
```bash
sudo systemctl enable lightdm
```

### Mesh & Radio Suite
Install complete mesh/SDR stack:
```bash
cd integrations
sudo ./install-integrations.sh --mesh-radio-suite
```

## Getting Help

- Documentation: `/usr/share/doc/icenet`
- Installation log: `/tmp/icenet-install.log`
- System log: `journalctl -xe`
- GitHub: https://github.com/IceNet-01/IceNet-OS

## Tips

### Test in Virtual Machine
Before creating USB:
```bash
qemu-system-x86_64 \
    -m 4G \
    -cdrom output/icenet-os-*.iso \
    -boot d \
    -enable-kvm
```

### Verify ISO Integrity
```bash
sha256sum -c output/icenet-os-*.iso.sha256
```

### Multi-Boot USB
Use GRUB2 or rEFInd to add IceNet-OS to existing multi-boot USB

### Network Install
For minimal bandwidth, use netinstall option (downloads packages during install)

---

**Next Steps:**
- Read full documentation: [README.md](README.md)
- Explore integrations: [../integrations/](../integrations/)
- Check mesh networking: [../integrations/mesh-radio-suite/](../integrations/mesh-radio-suite/)
