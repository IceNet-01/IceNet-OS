#!/bin/bash
# IceNet-OS v0.1 Build Script
# Compiles core components and creates release package

set -e

VERSION="0.1.0"
BUILD_DIR="/home/user/IceNet-OS"
RELEASE_DIR="$BUILD_DIR/release/v$VERSION"
DIST_DIR="$RELEASE_DIR/dist"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[BUILD]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

# Create release structure
prepare_release() {
    log "Preparing release directories..."
    rm -rf "$RELEASE_DIR"
    mkdir -p "$DIST_DIR"/{bin,lib,etc,doc,integrations}
}

# Compile init system
compile_init() {
    log "Compiling icenet-init..."

    cd "$BUILD_DIR/init"

    if [ -f "icenet-init.c" ]; then
        gcc -o icenet-init icenet-init.c -Wall -Wextra -O2
        strip icenet-init
        cp icenet-init "$DIST_DIR/bin/"
        log "✓ icenet-init compiled successfully"
    else
        warn "icenet-init.c not found, skipping"
    fi
}

# Compile package manager
compile_pkgmgr() {
    log "Compiling ice-pkg..."

    cd "$BUILD_DIR/pkgmgr"

    if [ -f "ice-pkg.c" ]; then
        if gcc -o ice-pkg ice-pkg.c -Wall -Wextra -O2 -lcurl 2>/dev/null; then
            strip ice-pkg
            cp ice-pkg "$DIST_DIR/bin/"
            log "✓ ice-pkg compiled successfully"
        else
            warn "ice-pkg requires libcurl-dev, skipping compilation"
            warn "Source code included in release for compilation on target system"
        fi
    else
        warn "ice-pkg.c not found, skipping"
    fi
}

# Compile utilities
compile_utilities() {
    log "Compiling core utilities..."

    # Network utilities
    if [ -d "$BUILD_DIR/core/netutils" ]; then
        cd "$BUILD_DIR/core/netutils"
        for src in *.c; do
            if [ -f "$src" ]; then
                binary="${src%.c}"
                log "  Compiling $binary..."
                gcc -o "$binary" "$src" -Wall -Wextra -O2 2>/dev/null || warn "Failed to compile $binary"
                if [ -f "$binary" ]; then
                    strip "$binary"
                    cp "$binary" "$DIST_DIR/bin/"
                fi
            fi
        done
    fi

    # System utilities
    if [ -d "$BUILD_DIR/core/sysutils" ]; then
        cd "$BUILD_DIR/core/sysutils"
        for src in *.c; do
            if [ -f "$src" ]; then
                binary="${src%.c}"
                log "  Compiling $binary..."
                gcc -o "$binary" "$src" -Wall -Wextra -O2 2>/dev/null || warn "Failed to compile $binary"
                if [ -f "$binary" ]; then
                    strip "$binary"
                    cp "$binary" "$DIST_DIR/bin/"
                fi
            fi
        done
    fi

    # File utilities
    if [ -d "$BUILD_DIR/core/fileutils" ]; then
        cd "$BUILD_DIR/core/fileutils"
        for src in *.c; do
            if [ -f "$src" ]; then
                binary="${src%.c}"
                log "  Compiling $binary..."
                gcc -o "$binary" "$src" -Wall -Wextra -O2 2>/dev/null || warn "Failed to compile $binary"
                if [ -f "$binary" ]; then
                    strip "$binary"
                    cp "$binary" "$DIST_DIR/bin/"
                fi
            fi
        done
    fi

    # Text utilities
    if [ -d "$BUILD_DIR/core/textutils" ]; then
        cd "$BUILD_DIR/core/textutils"
        for src in *.c; do
            if [ -f "$src" ]; then
                binary="${src%.c}"
                log "  Compiling $binary..."
                gcc -o "$binary" "$src" -Wall -Wextra -O2 2>/dev/null || warn "Failed to compile $binary"
                if [ -f "$binary" ]; then
                    strip "$binary"
                    cp "$binary" "$DIST_DIR/bin/"
                fi
            fi
        done
    fi

    log "✓ Utilities compiled"
}

# Copy scripts
copy_scripts() {
    log "Copying system scripts..."

    # Core scripts
    if [ -d "$BUILD_DIR/core/scripts" ]; then
        cp -r "$BUILD_DIR/core/scripts"/* "$DIST_DIR/bin/" 2>/dev/null || true
        chmod +x "$DIST_DIR/bin"/*.sh 2>/dev/null || true
    fi

    log "✓ Scripts copied"
}

# Copy integrations
copy_integrations() {
    log "Copying integrations..."

    if [ -d "$BUILD_DIR/integrations" ]; then
        cp -r "$BUILD_DIR/integrations"/* "$DIST_DIR/integrations/"
        chmod +x "$DIST_DIR/integrations"/*.sh 2>/dev/null || true
        chmod +x "$DIST_DIR/integrations"/*/*.sh 2>/dev/null || true
    fi

    log "✓ Integrations copied"
}

# Copy installer
copy_installer() {
    log "Copying live installer..."

    if [ -d "$BUILD_DIR/live-installer" ]; then
        cp -r "$BUILD_DIR/live-installer" "$DIST_DIR/"
    fi

    log "✓ Installer copied"
}

# Copy documentation
copy_docs() {
    log "Copying documentation..."

    cp "$BUILD_DIR/README.md" "$DIST_DIR/doc/"

    if [ -d "$BUILD_DIR/docs" ]; then
        cp -r "$BUILD_DIR/docs"/* "$DIST_DIR/doc/" 2>/dev/null || true
    fi

    log "✓ Documentation copied"
}

# Copy kernel configs
copy_kernel_configs() {
    log "Copying kernel configurations..."

    if [ -d "$BUILD_DIR/kernel" ]; then
        mkdir -p "$DIST_DIR/etc/kernel"
        cp -r "$BUILD_DIR/kernel"/* "$DIST_DIR/etc/kernel/"
    fi

    log "✓ Kernel configs copied"
}

# Copy source code
copy_source() {
    log "Copying source code..."

    mkdir -p "$DIST_DIR/src"

    # Copy all C source files
    cp -r "$BUILD_DIR/init" "$DIST_DIR/src/" 2>/dev/null || true
    cp -r "$BUILD_DIR/pkgmgr" "$DIST_DIR/src/" 2>/dev/null || true
    cp -r "$BUILD_DIR/core" "$DIST_DIR/src/" 2>/dev/null || true

    log "✓ Source code copied"
}

# Generate build info
generate_build_info() {
    log "Generating build information..."

    cat > "$DIST_DIR/BUILD_INFO.txt" <<EOF
IceNet-OS v$VERSION Build Information
=====================================

Build Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Build Host: $(uname -n)
Build System: $(uname -s) $(uname -r) $(uname -m)
Builder: IceNet-OS Build System

Components:
-----------
$(ls -1 "$DIST_DIR/bin/" | wc -l) binaries compiled
$(find "$DIST_DIR/integrations" -type f -name "*.sh" | wc -l) integration scripts
$(find "$DIST_DIR/doc" -type f | wc -l) documentation files

Installation:
-------------
See INSTALL.md for installation instructions

For live ISO/image creation:
  cd live-installer/iso-builder
  sudo ./build-iso.sh              (for x86_64)
  sudo ./build-arm-image.sh        (for ARM)

Support:
--------
GitHub: https://github.com/IceNet-01/IceNet-OS
Documentation: See doc/ directory

EOF

    log "✓ Build info generated"
}

# Create installation guide
create_install_guide() {
    log "Creating installation guide..."

    cat > "$DIST_DIR/INSTALL.md" <<'EOF'
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
EOF

    log "✓ Installation guide created"
}

# Create tarball
create_tarball() {
    log "Creating release tarball..."

    cd "$RELEASE_DIR"
    tar czf "icenet-os-v${VERSION}.tar.gz" dist/

    log "✓ Tarball created: $(du -h icenet-os-v${VERSION}.tar.gz | cut -f1)"
}

# Generate checksums
generate_checksums() {
    log "Generating checksums..."

    cd "$RELEASE_DIR"
    sha256sum "icenet-os-v${VERSION}.tar.gz" > "icenet-os-v${VERSION}.tar.gz.sha256"
    md5sum "icenet-os-v${VERSION}.tar.gz" > "icenet-os-v${VERSION}.tar.gz.md5"

    log "✓ Checksums generated"
}

# Create release notes
create_release_notes() {
    log "Creating release notes..."

    cat > "$RELEASE_DIR/RELEASE_NOTES.md" <<'EOF'
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
EOF

    log "✓ Release notes created"
}

# Main build process
main() {
    log "===== IceNet-OS v$VERSION Build ====="
    log "Build directory: $BUILD_DIR"
    log "Release directory: $RELEASE_DIR"
    echo ""

    prepare_release
    compile_init
    compile_pkgmgr
    compile_utilities
    copy_scripts
    copy_integrations
    copy_installer
    copy_docs
    copy_kernel_configs
    copy_source
    generate_build_info
    create_install_guide
    create_tarball
    generate_checksums
    create_release_notes

    echo ""
    log "===== Build Complete ====="
    log "Release package: $RELEASE_DIR/icenet-os-v${VERSION}.tar.gz"
    log "Size: $(du -h $RELEASE_DIR/icenet-os-v${VERSION}.tar.gz | cut -f1)"
    log ""
    log "Build artifacts:"
    ls -lh "$RELEASE_DIR" | tail -n +2
    echo ""
    log "To build a bootable ISO, extract the tarball and run:"
    log "  cd dist/live-installer/iso-builder"
    log "  sudo ./build-iso.sh"
    echo ""
    log "See RELEASE_NOTES.md and INSTALL.md for more information"
}

main "$@"
