# IceNet-OS Architecture

## Overview

IceNet-OS is designed as a multi-architecture operating system with a focus on embedded and edge computing platforms.

## System Layers

### 1. Hardware Layer
- **Zima boards**: x86_64 Intel/AMD processors
- **Raspberry Pi**: ARM Cortex-A (32-bit and 64-bit)

### 2. Bootloader Layer
- **x86_64**: GRUB2 or systemd-boot
- **ARM**: U-Boot or Raspberry Pi bootloader
- Custom boot configuration for fast boot times

### 3. Kernel Layer
- **Base**: Linux kernel (LTS versions)
- **Custom configurations**: Minimal modules, optimized for target hardware
- **Security**: Hardened kernel parameters, SELinux/AppArmor support
- **Size**: Minimal kernel image (~5-10MB)

### 4. Init System (icenet-init)
- **Design**: Custom lightweight init written in C/Rust
- **Features**:
  - Parallel service startup
  - Dependency management
  - Minimal overhead (<1MB)
  - Socket activation
  - Process supervision
- **No systemd**: We avoid the complexity of systemd

### 5. Core System
- **Shell**: Custom minimal shell or dash
- **Core utilities**: Busybox as base + custom tools
- **C Library**: musl libc (smaller, cleaner than glibc)
- **Package Manager**: ice-pkg (custom, simple, fast)

### 6. User Space
- Minimal by default
- Add packages as needed
- Focus on embedded/edge use cases

## File System Layout

```
/
├── boot/           # Kernel, initramfs, boot config
├── bin/            # Essential binaries
├── sbin/           # System binaries
├── lib/            # Essential libraries
├── etc/            # Configuration files
│   └── icenet/     # IceNet-OS specific config
├── usr/
│   ├── bin/        # User binaries
│   ├── lib/        # User libraries
│   └── share/      # Shared data
├── var/
│   ├── log/        # System logs
│   └── lib/ice-pkg/ # Package database
├── home/           # User home directories
├── tmp/            # Temporary files
├── dev/            # Device files
├── proc/           # Process information
├── sys/            # System information
└── run/            # Runtime data
```

## Security Model

1. **Minimal attack surface**: Only essential services running
2. **Secure defaults**: Everything disabled unless explicitly enabled
3. **Immutable system**: Core OS read-only, updates atomic
4. **User space isolation**: Proper privilege separation
5. **Verified boot**: Optional secure boot support

## Package Management

### ice-pkg Design
- **Simple format**: tar.xz with metadata
- **Dependency resolution**: Minimal, explicit dependencies
- **Binary packages**: Pre-compiled for each architecture
- **Source build support**: Optional source compilation
- **Repository structure**: Simple HTTP-based repos

### Package Database
- SQLite-based package tracking
- File ownership and conflict detection
- Clean upgrade and rollback support

## Build System

### Cross-Platform Build
- Single build system for all architectures
- Docker-based build environment
- Reproducible builds
- Output: bootable images for each platform

### Build Process
1. Compile kernel for target architecture
2. Build init system and core utilities
3. Construct minimal rootfs
4. Package base system
5. Create bootable image (ISO/IMG)

## Boot Process

### Zima Board (x86_64)
1. BIOS/UEFI → Bootloader (GRUB2)
2. Load kernel + initramfs
3. Kernel initializes hardware
4. Mount root filesystem
5. Start icenet-init
6. Launch system services

### Raspberry Pi (ARM)
1. GPU firmware → U-Boot/Pi bootloader
2. Load kernel + device tree + initramfs
3. Kernel initializes hardware
4. Mount root filesystem
5. Start icenet-init
6. Launch system services

## Performance Targets

- **Boot time**: < 5 seconds (kernel to login)
- **RAM usage**: < 100MB idle (base system)
- **Disk usage**: < 500MB (base installation)
- **Package install**: < 1 second (average package)

## Future Enhancements

- Custom microkernel option (long-term)
- Real-time kernel support
- Container runtime integration
- OTA update system
- Custom hardware drivers
