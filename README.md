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
- [x] Comprehensive documentation

## Contributing

This is an active development project. More details coming soon.

## License

MIT License - See LICENSE file for details
