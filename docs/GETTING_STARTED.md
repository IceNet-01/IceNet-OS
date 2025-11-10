# Getting Started with IceNet-OS

Welcome to IceNet-OS! This guide will help you get up and running quickly.

## What is IceNet-OS?

IceNet-OS is a minimal, secure, and performant operating system designed for:
- **Zima boards** (x86_64 architecture)
- **Raspberry Pi** (ARM architecture - Pi 2, 3, 4, 5)

It features:
- Custom lightweight init system (icenet-init)
- Simple package management (ice-pkg)
- Fast boot times (< 5 seconds)
- Minimal resource usage (< 100MB RAM)
- Security-focused design

## Quick Start

### Option 1: Download Pre-built Image (Recommended)

*Coming soon* - Pre-built images will be available for download.

### Option 2: Build from Source

```bash
# Clone repository
git clone https://github.com/IceNet-01/IceNet-OS.git
cd IceNet-OS

# Build for your platform
cd build
make setup
make image ARCH=x86_64    # For Zima boards
# OR
make image ARCH=aarch64   # For Raspberry Pi 4/5

# Image will be created in build-output/
```

See [BUILDING.md](BUILDING.md) for detailed build instructions.

## Installation

### Zima Board Installation

1. **Prepare Installation Media**
   ```bash
   # Write image to USB drive
   sudo dd if=icenet-os-x86_64-0.1.0.img of=/dev/sdX bs=4M status=progress
   sudo sync
   ```

2. **Boot from USB**
   - Insert USB drive into Zima board
   - Power on and enter BIOS (usually Delete or F2)
   - Select USB drive as boot device
   - IceNet-OS will boot

3. **Optional: Install to Internal Storage**
   ```bash
   # After booting from USB
   sudo dd if=/dev/sda of=/dev/mmcblk0 bs=4M status=progress
   ```

### Raspberry Pi Installation

1. **Prepare SD Card**
   ```bash
   # Write image to SD card
   sudo dd if=icenet-os-aarch64-0.1.0.img of=/dev/sdX bs=4M status=progress
   sudo sync
   ```

2. **Boot Raspberry Pi**
   - Insert SD card into Raspberry Pi
   - Connect power
   - IceNet-OS will boot automatically
   - Connect via HDMI to see boot process

3. **Default Login**
   ```
   Username: root
   Password: (no password by default - set one immediately!)
   ```

## First Steps After Installation

### 1. Set Root Password

**CRITICAL**: Set a root password immediately!

```bash
passwd root
```

### 2. Configure Network

#### DHCP (Automatic)
Network is configured automatically via DHCP by default.

#### Static IP
Edit `/etc/network/interfaces`:

```bash
vi /etc/network/interfaces
```

Change to:
```
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
```

Restart network:
```bash
ifdown eth0 && ifup eth0
```

### 3. Update Package Database

```bash
ice-pkg update
```

### 4. Install Essential Software

```bash
# Install text editor
ice-pkg install vim

# Install SSH server (for remote access)
ice-pkg install openssh

# Install development tools
ice-pkg install gcc make
```

## Basic System Administration

### Package Management

```bash
# Update package database
ice-pkg update

# Search for packages
ice-pkg search editor

# Install a package
ice-pkg install vim

# Remove a package
ice-pkg remove vim

# List installed packages
ice-pkg list

# Show package information
ice-pkg info vim
```

### Service Management

Services are defined in `/etc/icenet/services/`

#### View Running Services

```bash
# List all processes
ps aux
```

#### Create a Custom Service

Create a file in `/etc/icenet/services/myservice`:

```ini
# My custom service
exec=/usr/local/bin/myapp --daemon
depends=network
respawn=yes
```

Reboot to start the service:
```bash
reboot
```

#### Stop a Service

```bash
# Find the process
ps aux | grep myapp

# Kill it
kill <PID>
```

### System Configuration

#### Hostname

```bash
# Change hostname
echo "myhostname" > /etc/hostname
hostname -F /etc/hostname
```

#### Timezone

```bash
# Set timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
```

#### Locale

```bash
# Edit /etc/profile
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### User Management

```bash
# Add a new user
adduser myuser

# Add to sudoers (if sudo installed)
echo "myuser ALL=(ALL) ALL" >> /etc/sudoers

# Delete a user
deluser myuser
```

## Networking

### WiFi Configuration (Raspberry Pi)

```bash
# Install WiFi tools
ice-pkg install wpa_supplicant

# Create WiFi configuration
vi /etc/wpa_supplicant/wpa_supplicant.conf
```

Add:
```
network={
    ssid="YourWiFiName"
    psk="YourPassword"
}
```

Connect:
```bash
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
dhclient wlan0
```

### SSH Access

```bash
# Install SSH server
ice-pkg install openssh

# SSH service starts automatically
# Connect from another machine:
ssh root@<ip-address>
```

## Performance Tuning

### Optimize for Zima Board

```bash
# Enable performance governor
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

### Optimize for Raspberry Pi

```bash
# Edit /boot/config.txt
# Increase GPU memory for graphics applications
gpu_mem=128

# Overclock (Pi 4)
over_voltage=2
arm_freq=1800
```

## Troubleshooting

### System Won't Boot

1. Check boot media is properly written
2. Verify BIOS/boot settings
3. Try re-writing the image
4. Check hardware compatibility

### No Network Connection

```bash
# Check interface status
ip link show

# Bring up interface
ip link set eth0 up

# Request DHCP address
dhclient eth0

# Check for IP address
ip addr show
```

### Forgot Root Password

Boot with `init=/bin/sh` kernel parameter:
1. At GRUB menu, press 'e' to edit
2. Add `init=/bin/sh` to linux line
3. Press Ctrl+X to boot
4. Remount root as read-write:
   ```bash
   mount -o remount,rw /
   passwd root
   reboot -f
   ```

### Service Won't Start

```bash
# Check service definition
cat /etc/icenet/services/servicename

# Check logs (if syslog running)
tail -f /var/log/messages

# Start manually for debugging
/path/to/service --debug
```

## Next Steps

### Development

- [Building from Source](BUILDING.md)
- [Architecture Overview](ARCHITECTURE.md)
- [Contributing Guidelines](../CONTRIBUTING.md)

### Advanced Topics

- Setting up a development environment
- Creating custom packages
- Kernel customization
- Security hardening

### Get Help

- GitHub Issues: https://github.com/IceNet-01/IceNet-OS/issues
- Documentation: https://github.com/IceNet-01/IceNet-OS/tree/main/docs
- Community Forum: *Coming soon*

## Common Tasks

### Backup System

```bash
# Backup to external drive
dd if=/dev/mmcblk0 of=/mnt/backup/icenet-backup.img bs=4M status=progress
```

### Update System

```bash
# Update package database
ice-pkg update

# Upgrade packages (when available)
ice-pkg upgrade
```

### Monitor System Resources

```bash
# CPU and memory usage
top

# Disk usage
df -h

# Disk I/O
iostat
```

### Check System Logs

```bash
# View kernel messages
dmesg

# View system logs (if syslog running)
tail -f /var/log/messages

# View boot messages
less /var/log/boot.log
```

Welcome to IceNet-OS! Enjoy your lightweight, secure operating system.
