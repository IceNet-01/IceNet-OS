# IceNet-OS Meshtastic Bridge Headless Integration

Production-ready headless bridge service for Meshtastic radio networks on IceNet-OS.

## Overview

The headless Meshtastic bridge forwards messages bidirectionally between two USB-connected Meshtastic radios without GUI dependencies. Perfect for dedicated server installations, remote repeaters, and always-on relay stations.

## Features

- **Headless Operation**: Runs as background systemd service
- **Auto-Detection**: Automatically finds and connects to Meshtastic radios
- **Self-Healing**: Exponential backoff retry with automatic recovery
- **Message Deduplication**: 10-minute tracking window prevents loops
- **Health Monitoring**: JSON status files for external monitoring
- **Individual Radio Recovery**: Auto-reboots unresponsive radios
- **Resource Efficient**: ~50-100MB RAM, minimal CPU usage
- **Optional Mode**: Can be enabled/disabled without OS reinstallation

## Installation

### Via Package Manager (Recommended)
```bash
ice-pkg install meshtastic-bridge
```

This installs but **does NOT enable** the service by default.

### Manual Installation
```bash
cd /opt/icenet/meshtastic-bridge
sudo ./install-auto.sh
```

## Enabling the Service (Optional)

The bridge is installed but disabled by default. Enable it when needed:

```bash
# Enable and start immediately
sudo systemctl enable --now meshtastic-bridge

# Or configure and enable
sudo icenet-bridge-config
sudo systemctl enable meshtastic-bridge
sudo systemctl start meshtastic-bridge
```

## Configuration

### Interactive Configuration
```bash
sudo icenet-bridge-config
```

Guides you through:
- Radio detection and selection
- Deduplication window settings
- Reconnection parameters
- Logging preferences

### Manual Configuration

Edit `/etc/icenet/meshtastic-bridge.conf`:

```ini
[bridge]
# Auto-detect radios (recommended)
auto_detect = true

# Or specify manually
# radio1_port = /dev/ttyUSB0
# radio2_port = /dev/ttyUSB1

# Message handling
dedup_window_seconds = 600
max_message_cache = 10000

# Connection management
reconnect_min_delay = 2
reconnect_max_delay = 32
max_consecutive_failures = 3

# Monitoring
health_check_interval = 30
status_file = /var/lib/icenet/meshtastic-bridge/status.json

# Logging
log_level = INFO
log_to_journal = true
```

## Service Management

```bash
# Start service
sudo systemctl start meshtastic-bridge

# Stop service
sudo systemctl stop meshtastic-bridge

# Enable at boot
sudo systemctl enable meshtastic-bridge

# Disable at boot
sudo systemctl disable meshtastic-bridge

# Check status
sudo systemctl status meshtastic-bridge

# View logs
journalctl -u meshtastic-bridge -f

# View recent logs
journalctl -u meshtastic-bridge --since "1 hour ago"
```

## Monitoring

### Status File

Real-time JSON status at `/var/lib/icenet/meshtastic-bridge/status.json`:

```json
{
  "status": "running",
  "uptime_seconds": 86400,
  "radio1": {
    "connected": true,
    "port": "/dev/ttyUSB0",
    "last_message": 1234567890,
    "messages_forwarded": 1547,
    "errors": 2
  },
  "radio2": {
    "connected": true,
    "port": "/dev/ttyUSB1",
    "last_message": 1234567895,
    "messages_forwarded": 1543,
    "errors": 1
  },
  "dedup_cache_size": 847,
  "last_updated": 1234567900
}
```

### Command Line Status
```bash
icenet-bridge status
```

Shows:
- Service state (running/stopped)
- Connected radios
- Message counts
- Error rates
- Uptime

### Integration with System Monitoring
```bash
# Add to icetop monitoring
# Status appears in system service list

# Include in sysinfo output
sysinfo | grep -A 10 "Meshtastic Bridge"
```

## Use Cases

### Remote Repeater Station
```bash
# Install IceNet-OS on Raspberry Pi
# Connect two Meshtastic radios
# Enable bridge service
sudo systemctl enable --now meshtastic-bridge

# Verify operation
icenet-bridge status
```

### Dedicated Bridge Server
```bash
# Configure static IP
icenet-network static eth0 192.168.1.10 255.255.255.0 192.168.1.1

# Enable bridge
sudo systemctl enable --now meshtastic-bridge

# Monitor remotely
ssh user@192.168.1.10 'journalctl -u meshtastic-bridge -f'
```

### Testing Before Deployment
```bash
# Install but don't enable
ice-pkg install meshtastic-bridge

# Test manually
sudo /usr/bin/meshtastic-bridge --foreground

# If working, enable service
sudo systemctl enable meshtastic-bridge
```

### Optional Service on Multi-Purpose System
```bash
# Install IceNet-OS with all features
# Bridge is installed but inactive

# Enable only when needed
sudo systemctl start meshtastic-bridge

# Disable when not needed
sudo systemctl stop meshtastic-bridge
```

## Hardware Setup

### USB Connection
1. Connect first Meshtastic radio to USB port
2. Connect second Meshtastic radio to another USB port
3. Wait for auto-detection (~5 seconds)
4. Verify detection: `lsusb | grep "Future Technology"`

### Port Identification
```bash
# List USB serial ports
ls -l /dev/ttyUSB*

# Check which radio is which
for port in /dev/ttyUSB*; do
    echo "Port: $port"
    meshtastic --port $port --info | grep "Long name"
done
```

### USB Permissions
```bash
# Add user to dialout group
sudo usermod -a -G dialout meshtastic-bridge

# Or set udev rules (done by installer)
cat /etc/udev/rules.d/99-meshtastic.rules
```

## Performance

- **Memory**: 50-100MB typical
- **CPU**: <2% average
- **Startup time**: ~5 seconds
- **Message latency**: <100ms typical
- **Max throughput**: 50+ messages/second

## Reliability Features

### Automatic Reconnection
If a radio disconnects:
1. Detects loss within 5 seconds
2. Attempts reconnection with exponential backoff
3. Starts at 2 seconds, doubles each retry
4. Caps at 32 seconds between attempts
5. Continues indefinitely until reconnected

### Radio Recovery
After 3 consecutive failures:
1. Attempts radio reboot command
2. Waits for radio to restart
3. Reconnects automatically
4. Logs recovery action

### Message Deduplication
- Tracks message IDs in rolling 10-minute window
- Prevents forwarding loops
- Configurable cache size
- Automatic cleanup of old entries

## Security

- **No network exposure**: USB serial only
- **User isolation**: Runs as dedicated user
- **Private temporary files**: PrivateTmp=true
- **Protected system**: ProtectSystem=strict
- **No new privileges**: NoNewPrivileges=true

## Troubleshooting

### Service Won't Start
```bash
# Check logs
journalctl -u meshtastic-bridge --no-pager

# Verify radios connected
lsusb | grep "Future Technology"

# Test manually
sudo /usr/bin/meshtastic-bridge --foreground --debug
```

### Radios Not Detected
```bash
# Check USB ports
ls -l /dev/ttyUSB*

# Check permissions
groups meshtastic-bridge

# Check radio power
# Some radios require external power for full operation
```

### Messages Not Forwarding
```bash
# Check radio channels match
meshtastic --port /dev/ttyUSB0 --info
meshtastic --port /dev/ttyUSB1 --info

# Verify radios can communicate
# Test with handheld or second node

# Check deduplication isn't too aggressive
# Reduce window if needed
```

### High CPU/Memory Usage
```bash
# Check message rate
icenet-bridge status

# Reduce deduplication cache if very high message volume
sudo icenet-bridge-config

# Monitor resource usage
icetop | grep meshtastic-bridge
```

## Comparison: GUI vs Headless

| Feature | GUI Version | Headless Version |
|---------|-------------|------------------|
| Display | Required | None |
| Memory | 150-250MB | 50-100MB |
| CPU | 5-20% | <2% |
| Configuration | Visual | Config file |
| Monitoring | Dashboard | JSON + logs |
| Auto-start | Optional | Systemd |
| Remote management | No | SSH + systemctl |
| Best for | Desktop, testing | Servers, production |

## Integration with Other Components

### With Thermal Management
```bash
# Enable thermal protection for outdoor installation
ice-pkg install thermal-mgmt
sudo systemctl enable icenet-thermal

# Enable bridge service
sudo systemctl enable meshtastic-bridge
```

### With Network Configuration
```bash
# Configure static IP for remote access
icenet-network static eth0 192.168.1.10 255.255.255.0 192.168.1.1

# Enable SSH for remote management
ice-pkg install openssh
sudo systemctl enable sshd
```

### With Monitoring
```bash
# Include bridge status in sysinfo
sysinfo

# Monitor with top
icetop

# Check network stats
icenetstat
```

## Updating

```bash
# Via package manager
ice-pkg update
ice-pkg upgrade meshtastic-bridge

# Service automatically restarts after update
```

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop meshtastic-bridge
sudo systemctl disable meshtastic-bridge

# Remove package
ice-pkg remove meshtastic-bridge

# Clean up configuration (optional)
sudo rm -rf /etc/icenet/meshtastic-bridge.conf
sudo rm -rf /var/lib/icenet/meshtastic-bridge
```

## Source

Integrated from: https://github.com/IceNet-01/meshtastic-bridge-headless

## Dependencies

- Python 3.8+
- meshtastic ≥2.7.0
- pyserial ≥3.5
- rich ≥14.2.0
- systemd

## License

See source repository for license information.
