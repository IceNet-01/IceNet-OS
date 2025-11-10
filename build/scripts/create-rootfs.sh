#!/bin/bash
# IceNet-OS Root Filesystem Creator
#
# Creates a minimal root filesystem for IceNet-OS

set -e

ARCH=${1:-x86_64}
ROOTFS_DIR=${2:-/tmp/icenet-rootfs}

echo "Creating IceNet-OS root filesystem for $ARCH..."

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$ROOTFS_DIR"/{bin,sbin,etc,proc,sys,dev,run,tmp,var,usr,home,root}
mkdir -p "$ROOTFS_DIR"/usr/{bin,sbin,lib,share}
mkdir -p "$ROOTFS_DIR"/var/{log,lib,cache}
mkdir -p "$ROOTFS_DIR"/etc/{icenet,network}
mkdir -p "$ROOTFS_DIR"/etc/icenet/services

# Set proper permissions
chmod 1777 "$ROOTFS_DIR"/tmp
chmod 700 "$ROOTFS_DIR"/root

echo "Root filesystem structure created at $ROOTFS_DIR"

# Create essential configuration files
echo "Creating configuration files..."

# /etc/hostname
echo "icenet" > "$ROOTFS_DIR/etc/hostname"

# /etc/hosts
cat > "$ROOTFS_DIR/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   icenet
::1         localhost ip6-localhost ip6-loopback
EOF

# /etc/passwd
cat > "$ROOTFS_DIR/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
nobody:x:65534:65534:nobody:/:/bin/false
EOF

# /etc/group
cat > "$ROOTFS_DIR/etc/group" << 'EOF'
root:x:0:
nogroup:x:65534:
EOF

# /etc/shadow
cat > "$ROOTFS_DIR/etc/shadow" << 'EOF'
root:!:19000:0:99999:7:::
nobody:!:19000:0:99999:7:::
EOF
chmod 640 "$ROOTFS_DIR/etc/shadow"

# /etc/fstab
cat > "$ROOTFS_DIR/etc/fstab" << 'EOF'
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults        0       0
sysfs           /sys            sysfs   defaults        0       0
devtmpfs        /dev            devtmpfs mode=0755     0       0
tmpfs           /run            tmpfs   mode=0755      0       0
tmpfs           /tmp            tmpfs   mode=1777      0       0
EOF

# /etc/profile
cat > "$ROOTFS_DIR/etc/profile" << 'EOF'
# IceNet-OS System Profile

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PS1='\u@\h:\w\$ '

# Set umask
umask 022

# Load user profile if it exists
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi
EOF

# /etc/motd
cat > "$ROOTFS_DIR/etc/motd" << 'EOF'

  ___          _  _      _     ___  ___
 |_ _|__ ___ _| \| |___ | |_  / _ \/ __|
  | |/ _/ -_)_| .` / -_)|  _|| (_) \__ \
 |___\__\___(_)_|\_\___| \__| \___/|___/

 IceNet-OS v0.1.0 - Arctic Dawn Release

 A minimal, secure operating system
 https://github.com/IceNet-01/IceNet-OS

EOF

# Create inittab for our custom init
cat > "$ROOTFS_DIR/etc/inittab" << 'EOF'
# IceNet-OS inittab - not used by icenet-init
# Kept for compatibility
EOF

# Network configuration
cat > "$ROOTFS_DIR/etc/network/interfaces" << 'EOF'
# Network interface configuration

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# DNS configuration
cat > "$ROOTFS_DIR/etc/resolv.conf" << 'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

echo "Configuration files created"

# Create device nodes (minimal set)
echo "Creating device nodes..."
cd "$ROOTFS_DIR/dev"
if command -v mknod >/dev/null 2>&1; then
    mknod -m 666 null c 1 3 2>/dev/null || true
    mknod -m 666 zero c 1 5 2>/dev/null || true
    mknod -m 666 random c 1 8 2>/dev/null || true
    mknod -m 666 urandom c 1 9 2>/dev/null || true
    mknod -m 666 tty c 5 0 2>/dev/null || true
    mknod -m 600 console c 5 1 2>/dev/null || true
fi
cd - >/dev/null

echo "Root filesystem created successfully!"
echo "Location: $ROOTFS_DIR"
echo "Size: $(du -sh $ROOTFS_DIR | cut -f1)"
