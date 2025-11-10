# IceNet-OS v0.1.0 Release

**Release Date:** November 10, 2025
**Release Type:** Initial Public Release
**Package:** icenet-os-v0.1.0.tar.gz (130KB)

## What's Included

This is the first official release of IceNet-OS, providing the complete source code, build system, and precompiled binaries for supported utilities.

### Package Contents

- **11 Compiled Binaries**
  - `icenet-init` - Custom lightweight init system (19KB)
  - `iceping`, `icenetstat` - Network utilities
  - `icedf`, `icefree` - System monitoring
  - `icels`, `icecat`, `icegrep` - File and text utilities
  - `icenet-network`, `icenet-sysinfo` - System management scripts

- **Complete Source Code**
  - All C source files for core components
  - Ready to compile on target architectures
  - Includes init system, package manager, and utilities

- **Live Installer System**
  - ISO builder for x86_64 (Zima boards)
  - ARM image builder for Raspberry Pi
  - GTK3 graphical installer
  - ncurses text-based installer
  - Complete live boot infrastructure

- **Integrations**
  - Thermal management system
  - Meshtastic bridge (headless and GUI)
  - Desktop environment (Openbox-based)
  - Mesh & Radio Suite (Meshtastic, Reticulum, LoRa, SDR)

- **Documentation**
  - Complete installation guides
  - Quick start documentation
  - Integration documentation
  - Build instructions

## Quick Start

### Extract the Package

```bash
tar xzf icenet-os-v0.1.0.tar.gz
cd dist
```

### Build a Live ISO

```bash
# For x86_64 (Zima boards)
cd live-installer/iso-builder
sudo ./build-iso.sh

# For ARM (Raspberry Pi)
sudo ./build-arm-image.sh
```

This will create a bootable ISO/image that can be written to USB/SD card.

### Write to USB/SD Card

```bash
# For x86_64
sudo dd if=output/icenet-os-*.iso of=/dev/sdX bs=4M status=progress

# For ARM
sudo dd if=output/icenet-os-arm-*.img of=/dev/sdX bs=4M status=progress
```

### Boot and Install

1. Boot from USB/SD card
2. Choose "Live Mode" or "Install"
3. Use GUI installer (desktop icon) or CLI (`sudo icenet-install`)

## System Requirements

### Build Requirements
- Debian/Ubuntu-based Linux system
- Root access (for ISO building)
- 4GB+ disk space
- Build tools: gcc, make, debootstrap, squashfs-tools

### Runtime Requirements
- **x86_64**: Any 64-bit x86 CPU, 2GB+ RAM
- **ARM**: Raspberry Pi 3/4/5, 2GB+ RAM
- 16GB+ storage for installation

## Verification

Verify package integrity:

```bash
sha256sum -c icenet-os-v0.1.0.tar.gz.sha256
```

Expected SHA256:
```
5302b195f3b6324949e05ba712d26815e2cfc7c53bc8e38044936ca2a57337d9
```

## Documentation

- **INSTALL.md** - Detailed installation instructions
- **RELEASE_NOTES.md** - Complete release notes with feature list
- **BUILD_INFO.txt** - Build metadata
- **dist/doc/** - Full documentation set

## Support

- **GitHub**: https://github.com/IceNet-01/IceNet-OS
- **Documentation**: See `dist/doc/` directory
- **Issues**: Use GitHub issue tracker

## What's Next

See RELEASE_NOTES.md for the v0.2 roadmap.

Planned features:
- Native package repository
- OTA update system
- Web-based administration
- Enhanced hardware support

## License

MIT License - See LICENSE file in main repository

---

**Thank you for trying IceNet-OS v0.1.0!**

This is the first step in creating a modern, purpose-built operating system for edge computing, mesh networking, and SDR applications.
