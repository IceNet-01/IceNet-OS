# IceNet-OS Thermal Management Integration

Integration of the thermal-management-system for IceNet-OS.

## Overview

The thermal management system protects IceNet-OS installations in cold environments by using controlled CPU heating to prevent equipment from freezing. This is particularly useful for:

- Remote tower installations
- Outdoor enclosures
- Cold weather deployments
- Raspberry Pi and Zima board installations in unheated spaces

## Features

- **Automatic temperature monitoring** every 10 seconds
- **CPU-based heating** when temperature drops below 0°C (32°F)
- **Smart deactivation** at 5°C (41°F) with hysteresis
- **Multi-core load distribution** at 70% to preserve system resources
- **Systemd integration** for automatic startup
- **Terminal GUI dashboard** for monitoring (optional)

## Installation

### Quick Install
```bash
ice-pkg install thermal-mgmt
```

### Manual Installation
```bash
cd /opt/icenet/thermal-mgmt
sudo ./install.sh
```

## Configuration

Edit `/etc/icenet/thermal-mgmt.conf`:

```ini
[thermal]
# Temperature thresholds (Celsius)
heat_threshold = 0.0
stop_threshold = 5.0

# CPU heating parameters
cpu_load_percent = 70
check_interval = 10

# Enable GUI dashboard
enable_gui = false
```

## Service Management

```bash
# Start thermal management
sudo systemctl start icenet-thermal

# Enable at boot
sudo systemctl enable icenet-thermal

# Check status
sudo systemctl status icenet-thermal

# View logs
journalctl -u icenet-thermal -f
```

## Monitoring

### View Dashboard (if GUI enabled)
```bash
sudo icenet-thermal-gui
```

### Check Current Status
```bash
icenet-thermal status
```

Shows:
- Current temperature
- Heating status (active/inactive)
- CPU load
- Time since last state change

## Performance Impact

- **Memory usage**: ~50MB
- **Idle CPU usage**: <1%
- **Heating CPU usage**: 70% of available cores
- **Temperature increase**: +7-10°C typical, +17°C maximum

## Hardware Requirements

- Linux system with thermal sensors at `/sys/class/thermal/`
- Python 3.8+
- Multi-core CPU (2+ cores recommended)

## Use Cases

**Outdoor Meshtastic Nodes**
```bash
# Install with GUI for initial testing
ice-pkg install thermal-mgmt
sudo systemctl enable icenet-thermal
```

**Remote Repeater Stations**
```bash
# Headless installation
ice-pkg install thermal-mgmt-headless
# Configure for automatic start
sudo icenet-thermal config --headless
```

**Development and Testing**
```bash
# Run with dashboard
sudo icenet-thermal-gui
```

## Integration with IceNet-OS

The thermal management system integrates seamlessly with:
- **Init system**: Managed by icenet-init
- **Package manager**: Installable via ice-pkg
- **Logging**: Uses system journal
- **Monitoring**: Shows in sysinfo output

## Troubleshooting

### No thermal sensors found
```bash
# Check for thermal sensors
ls /sys/class/thermal/thermal_zone*/temp

# If none exist, system may not support thermal monitoring
```

### Heating not activating
```bash
# Check current temperature
cat /sys/class/thermal/thermal_zone0/temp

# Check service status
sudo systemctl status icenet-thermal

# Verify configuration
cat /etc/icenet/thermal-mgmt.conf
```

### High CPU usage when not heating
```bash
# Check for runaway processes
icetop

# Restart service
sudo systemctl restart icenet-thermal
```

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop icenet-thermal
sudo systemctl disable icenet-thermal

# Remove package
ice-pkg remove thermal-mgmt
```

## Source

Integrated from: https://github.com/IceNet-01/thermal-management-system

## License

See source repository for license information.
