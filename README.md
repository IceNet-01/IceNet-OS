# IceNet-OS

A modern, fully-featured operating system designed for Zima boards and Raspberry Pi platforms.

## Vision

IceNet-OS aims to be a lean, secure, and performant operating system that learns from decades of OS development. Built with modern practices and cross-platform support from the ground up.

## Target Platforms

- **Zima boards** (x86_64 architecture)
- **Raspberry Pi** (ARM architecture - Pi 3, 4, 5)

## Architecture

IceNet-OS uses a pragmatic approach:
- **Kernel**: Linux kernel (customized and optimized)
- **Userspace**: Completely custom implementation
- **Init System**: Custom lightweight init (icenet-init)
- **Package Manager**: Custom package management (ice-pkg)
- **Core Utilities**: Comprehensive system utilities
  - Network tools (ping, netstat, wget)
  - System monitoring (top, free, df)
  - File management (ls, cat, grep)
  - Network configuration scripts
- **Integrated Software**: Optional specialized components
  - Thermal management for cold environments
  - Meshtastic radio bridge (headless and GUI)
  - Network mesh management tools

## Design Principles

1. **Security First**: Minimal attack surface, secure by default
2. **Performance**: Optimized for embedded and edge computing
3. **Simplicity**: Clean, understandable codebase
4. **Cross-Platform**: Single codebase for x86_64 and ARM
5. **Modern**: Learning from past mistakes, implementing best practices

## Project Structure

```
IceNet-OS/
├── kernel/          # Kernel configuration and patches
├── bootloader/      # Boot configuration for both platforms
├── init/            # Custom init system
├── core/            # Core system utilities
│   ├── netutils/    # Network utilities (ping, netstat, wget)
│   ├── sysutils/    # System monitoring (top, free, df)
│   ├── fileutils/   # File operations (ls)
│   ├── textutils/   # Text processing (cat, grep)
│   └── scripts/     # Management scripts
├── pkgmgr/          # Package manager implementation
├── rootfs/          # Root filesystem structure
├── build/           # Build system and tools
├── integrations/    # Integrated software components
│   ├── thermal-mgmt/        # Thermal management system
│   ├── meshtastic-bridge/   # Meshtastic bridge (headless)
│   └── mesh-bridge-gui/     # Mesh bridge GUI
└── docs/            # Documentation
```

## Build Requirements

- Cross-compilation toolchains (x86_64 and ARM)
- Linux kernel source
- Build essentials (make, gcc, binutils)

## Current Status

**Phase 1: Foundation** - Complete
- [x] Project initialization
- [x] Build system setup
- [x] Kernel configuration
- [x] Custom init system
- [x] Package manager
- [x] Core utilities suite
- [x] Network management tools
- [x] Integrated software components
- [x] Comprehensive documentation

## Integrated Software

IceNet-OS includes native integration for specialized applications:

### Thermal Management System
Automatic CPU-based heating to prevent equipment freezing in cold environments. Perfect for outdoor installations and remote deployments.

**Installation**: `cd integrations && sudo ./install-integrations.sh --thermal`

### Meshtastic Bridge (Headless)
Production-ready bridge service for Meshtastic radio networks. Forwards messages between radios with automatic recovery and monitoring.

**Installation**: `cd integrations && sudo ./install-integrations.sh --bridge`
**Note**: Installed but disabled by default. Enable when needed.

### Mesh Bridge GUI
Desktop application for visual configuration and monitoring of Meshtastic radio bridges.

**Installation**: `cd integrations && sudo ./install-integrations.sh --gui`

### Desktop Environment (Optional)
Lightweight graphical desktop environment with taskbar, start menu, and full GUI for all tools.

**Installation**: `cd integrations && sudo ./install-integrations.sh --desktop`
**Boot**: System offers GUI/Shell choice at startup (defaults to shell after timeout)
**Features**: Xorg, Openbox, tint2 panel, jgmenu start menu, all IceNet tools with icons

### Mesh & Radio Suite (Turnkey Solution)
Complete turnkey solution for mesh networking, LoRa communications, and Software Defined Radio (SDR).

**Included Software**:
- **Microsoft Edge** - Modern Chromium-based browser
- **Meshtastic Ecosystem** - Complete toolset (CLI, flasher, web interface)
- **Reticulum Stack** - Cryptographic mesh protocol with NomadNet, Sideband, LXMF
- **LoRa Suite** - ChirpStack, gateway software, packet tools
- **SDR Suite** - GNU Radio, GQRX, SDR++, dump1090, rtl_433, Ham radio tools
- **Mesh Protocols** - Yggdrasil, cjdns, Babel, BATMAN-adv

**Installation**: `cd integrations && sudo ./install-integrations.sh --mesh-radio-suite`
**Quick Start**: See [integrations/mesh-radio-suite/QUICKSTART.md](integrations/mesh-radio-suite/QUICKSTART.md)
**Full Documentation**: See [integrations/mesh-radio-suite/README.md](integrations/mesh-radio-suite/README.md)

All software appears in desktop start menu with organized categories and icons.

**Documentation**: See [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md) for complete guide.

## Contributing

This is an active development project. More details coming soon.

## License

MIT License - See LICENSE file for details
