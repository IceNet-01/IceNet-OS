# Building IceNet-OS

This guide covers building IceNet-OS from source for all supported platforms.

## Prerequisites

### Required Tools

#### For all platforms:
```bash
# Debian/Ubuntu
sudo apt-get install build-essential git wget curl bc bison flex \
    libssl-dev libelf-dev libncurses-dev

# Arch Linux
sudo pacman -S base-devel git wget curl bc bison flex \
    openssl elfutils ncurses
```

#### For cross-compilation:
```bash
# x86_64 to ARM64
sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# x86_64 to ARMv7
sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
```

#### Optional (for creating bootable images):
```bash
sudo apt-get install grub-pc-bin grub-efi-amd64-bin parted dosfstools
```

### System Requirements

- **RAM**: Minimum 4GB, recommended 8GB+
- **Disk Space**: ~20GB for full build with all architectures
- **OS**: Linux (any modern distribution)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/IceNet-01/IceNet-OS.git
cd IceNet-OS

# Build for your current architecture (x86_64)
cd build
make setup
make image

# The bootable image will be in ../build-output/
```

## Building for Specific Platforms

### Zima Board (x86_64)

```bash
cd build
make setup
make ARCH=x86_64 kernel
make ARCH=x86_64 init
make ARCH=x86_64 core
make ARCH=x86_64 image
```

Output: `build-output/icenet-os-x86_64-0.1.0.img`

### Raspberry Pi 4/5 (ARM64)

```bash
cd build
make setup
make ARCH=aarch64 kernel
make ARCH=aarch64 init
make ARCH=aarch64 core
make ARCH=aarch64 image
```

Output: `build-output/icenet-os-aarch64-0.1.0.img`

### Raspberry Pi 2/3 (ARMv7 32-bit)

```bash
cd build
make setup
make ARCH=armv7 kernel
make ARCH=armv7 init
make ARCH=armv7 core
make ARCH=armv7 image
```

Output: `build-output/icenet-os-armv7-0.1.0.img`

## Building All Platforms

```bash
cd build
make all-images
```

This will build bootable images for all supported architectures.

## Build System Overview

### Directory Structure

```
build/
├── Makefile              # Main build system
├── scripts/
│   ├── create-rootfs.sh  # Root filesystem creator
│   └── create-image.sh   # Bootable image creator
└── build-output/         # Build artifacts (created)
    ├── linux-6.6.0/      # Kernel source
    ├── rootfs/           # Root filesystem
    └── *.img             # Bootable images
```

### Build Targets

- `make setup` - Create build directories and check tools
- `make kernel` - Build Linux kernel
- `make init` - Build custom init system
- `make core` - Build core utilities
- `make rootfs` - Create root filesystem
- `make image` - Create bootable image
- `make all-images` - Build for all architectures
- `make clean` - Remove build artifacts
- `make distclean` - Remove everything including cache

### Build Process

1. **Setup**: Creates necessary directories and verifies tools
2. **Kernel**: Downloads, configures, and compiles Linux kernel
3. **Init**: Compiles icenet-init system
4. **Core**: Builds core utilities and tools
5. **Rootfs**: Creates minimal root filesystem structure
6. **Image**: Packages everything into a bootable disk image

## Customizing the Build

### Kernel Configuration

Kernel configs are in `kernel/config-ARCH`. To customize:

```bash
# Extract kernel source
cd build
make extract-kernel

# Configure interactively
cd ../build-output/linux-6.6.0
make ARCH=x86_64 menuconfig

# Save configuration
cp .config ../../kernel/config-x86_64
```

### Adding Software to Root Filesystem

Edit `build/scripts/create-rootfs.sh` to add custom files, scripts, or configurations.

### Modifying Init Services

Service definitions are in `rootfs/etc/icenet/services/`. Each service is a simple text file:

```ini
# Service name
exec=/path/to/executable --args
depends=other-service
respawn=yes
```

## Troubleshooting

### Build Fails with "Permission Denied"

Some operations require root privileges (creating device nodes, mounting filesystems):

```bash
sudo make image
```

### Cross-compilation Fails

Ensure cross-compilation toolchains are installed:

```bash
# Check for ARM64 compiler
aarch64-linux-gnu-gcc --version

# Check for ARMv7 compiler
arm-linux-gnueabihf-gcc --version
```

### Kernel Build Fails

Common issues:
- Missing development headers: Install `linux-headers` package
- Insufficient disk space: Clean old builds with `make clean`
- Configuration errors: Start from default config with `make kernel-config`

### Image Creation Fails

Image creation requires:
- Root privileges (for loop devices and mounting)
- Loop device support in kernel
- Sufficient disk space (~2GB per image)

```bash
# Check loop device support
lsmod | grep loop

# Load loop module if needed
sudo modprobe loop
```

## Advanced Topics

### Adding Custom Packages

1. Create package structure
2. Build package with `ice-pkg` tools
3. Add to repository or install locally

### Modifying the Init System

The init system source is in `init/icenet-init.c`. After modifications:

```bash
cd init
make clean
make
sudo make install DESTDIR=../build-output/rootfs
```

### Building with Custom Compiler Flags

```bash
make CFLAGS="-O3 -march=native" kernel
```

### Creating a Development Environment

```bash
# Install to a chroot
sudo ./build/scripts/create-rootfs.sh x86_64 /tmp/icenet-chroot
sudo chroot /tmp/icenet-chroot /bin/sh
```

## Performance Tips

- Use `-j$(nproc)` for parallel compilation (automatic in Makefile)
- Enable ccache for faster rebuilds: `export CC="ccache gcc"`
- Build on SSD for faster I/O
- Allocate sufficient RAM (8GB+ recommended)

## Testing Images

### QEMU (x86_64)

```bash
qemu-system-x86_64 \
    -drive file=build-output/icenet-os-x86_64-0.1.0.img,format=raw \
    -m 1024 \
    -enable-kvm
```

### QEMU (ARM64)

```bash
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a72 \
    -m 1024 \
    -drive file=build-output/icenet-os-aarch64-0.1.0.img,format=raw \
    -nographic
```

### Physical Hardware

Write image to SD card or USB drive:

```bash
# WARNING: This will erase all data on the target device
sudo dd if=build-output/icenet-os-x86_64-0.1.0.img of=/dev/sdX bs=4M status=progress
sudo sync
```

Replace `/dev/sdX` with your actual device (use `lsblk` to identify).

## Next Steps

- See [DEVELOPMENT.md](DEVELOPMENT.md) for development guidelines
- See [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Join our community at https://github.com/IceNet-01/IceNet-OS
