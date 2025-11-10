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
- **Core Utilities**: Minimal, security-focused implementations

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

**Phase 1: Foundation** - In Progress
- [x] Project initialization
- [ ] Build system setup
- [ ] Kernel configuration
- [ ] Basic rootfs structure

## Contributing

This is an active development project. More details coming soon.

## License

MIT License - See LICENSE file for details
