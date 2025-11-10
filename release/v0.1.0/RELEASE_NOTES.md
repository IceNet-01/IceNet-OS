# IceNet-OS v0.1.0 Release Notes

**Release Date:** $(date +%Y-%m-%d)

## Overview

First public release of IceNet-OS - a modern, lean operating system designed for edge computing, mesh networking, and SDR applications.

## Features

### Core System
- ✅ Custom lightweight init system (icenet-init)
- ✅ Package manager (ice-pkg)
- ✅ Comprehensive utilities suite
  - Network tools (ping, netstat, wget)
  - System monitoring (top, free, df)
  - File management utilities
  - Text processing tools

### Installation
- ✅ Live USB/SD card boot
- ✅ Graphical installer (GTK3-based)
- ✅ Text-based installer (ncurses)
- ✅ Persistence support
- ✅ Load-to-RAM option

### Desktop Environment
- ✅ Lightweight Openbox-based desktop
- ✅ tint2 panel with taskbar
- ✅ jgmenu start menu
- ✅ Boot menu (GUI/Shell choice)

### Mesh & Radio Suite
- ✅ Microsoft Edge browser
- ✅ Complete Meshtastic ecosystem
- ✅ Reticulum stack (NomadNet, Sideband, LXMF)
- ✅ LoRa software (ChirpStack, gateways)
- ✅ SDR suite (GNU Radio, GQRX, SDR++)
- ✅ Mesh protocols (Yggdrasil, cjdns, Babel, BATMAN)

### Specialized Integrations
- ✅ Thermal management system
- ✅ Meshtastic bridge (headless)
- ✅ Mesh bridge GUI

## Supported Platforms

- **x86_64**: Zima boards and compatible systems
- **ARM**: Raspberry Pi 3, 4, 5

## Installation

See INSTALL.md for detailed installation instructions.

Quick start:
```bash
cd live-installer/iso-builder
sudo ./build-iso.sh              # x86_64
sudo ./build-arm-image.sh        # ARM
```

## Known Limitations

- Full ISO build requires system with root access
- Some utilities require compilation on target architecture
- Desktop environment requires manual start on first boot

## Documentation

- README.md - Project overview
- INSTALL.md - Installation guide
- live-installer/QUICKSTART.md - Live USB quick start
- live-installer/README.md - Complete installer documentation
- integrations/mesh-radio-suite/README.md - Mesh/SDR documentation

## Roadmap

### v0.2 (Planned)
- Compiled kernel packages
- Native package repository
- OTA update system
- Enhanced hardware support

### v0.3 (Planned)
- Web-based administration interface
- Container support
- Advanced mesh routing
- IoT device integration

## Credits

IceNet-OS is built on the shoulders of giants, leveraging:
- Linux kernel
- Debian ecosystem
- Meshtastic project
- Reticulum network stack
- GNU Radio project
- And many other open source projects

## License

MIT License - See LICENSE file

## Support

- GitHub: https://github.com/IceNet-01/IceNet-OS
- Documentation: See doc/ directory
- Issues: GitHub issue tracker

---

**Thank you for trying IceNet-OS v0.1!**
