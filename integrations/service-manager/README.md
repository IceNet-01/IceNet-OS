# IceNet Service Manager

Easy-to-use control panel for managing IceNet system services and integrations.

## Overview

The IceNet Service Manager provides both graphical and command-line interfaces for controlling which services run on your IceNet-OS system. All integrations are pre-installed but disabled by default - you choose what runs.

## Pre-Installed Services

Three specialized services come pre-installed with IceNet-OS:

### 🌡️ Thermal Management
**Service**: `icenet-thermal`

Keeps hardware warm in cold environments by activating CPU-based heating when temperatures drop below 10°C. Perfect for:
- Outdoor installations
- Cold storage facilities
- Remote deployments
- Winter operations

**Default State**: Disabled

### 📡 Meshtastic Bridge (Headless)
**Service**: `meshtastic-bridge`

Headless bridge service for Meshtastic radio networks. Forwards messages between radios with automatic recovery and monitoring. Features:
- Automatic device connection
- Message bridging between radios
- Self-healing with exponential backoff
- Comprehensive logging

**Default State**: Disabled (as requested)

### 🖥️ Mesh Bridge GUI
**Service**: `mesh-bridge-gui`

Visual interface for configuring and monitoring mesh bridge operations. Provides:
- Radio status monitoring
- Configuration management
- Message traffic visualization
- Network topology display

**Default State**: Disabled

## Using the Service Manager

### Graphical Interface (Recommended)

Launch from:
- **Start Menu**: Settings → IceNet Service Manager
- **Command Line**: `icenet-service-manager`

The GUI provides:
- **Toggle Switches**: Enable/disable services at boot
- **Start/Stop Buttons**: Control services immediately
- **Status Indicators**: See if services are running
- **Real-time Updates**: Refresh button to check status

#### Quick Actions

1. **Enable Service at Boot**
   - Toggle switch to ON
   - Service will start automatically on next boot
   - Can start immediately with "Start" button

2. **Disable Service**
   - Toggle switch to OFF
   - Service won't start on boot
   - Can stop immediately with "Stop" button

3. **Start Service Now**
   - Click "▶ Start" button
   - Service runs immediately
   - Doesn't affect boot settings

4. **Stop Service**
   - Click "⬛ Stop" button
   - Service stops immediately
   - Doesn't affect boot settings

### Command-Line Interface

For headless systems or automation:

```bash
# List all services and their status
icenet-services list

# Enable service at boot
icenet-services enable thermal
icenet-services enable meshtastic
icenet-services enable mesh-gui

# Disable service from boot
icenet-services disable thermal

# Start service now
icenet-services start meshtastic

# Stop service
icenet-services stop meshtastic

# Restart service
icenet-services restart thermal

# Show detailed status
icenet-services status meshtastic

# Show help
icenet-services help
```

## Service Names

| Friendly Name | CLI Name | Service Unit |
|---------------|----------|--------------|
| Thermal Management | `thermal` | `icenet-thermal.service` |
| Meshtastic Bridge | `meshtastic` | `meshtastic-bridge.service` |
| Mesh Bridge GUI | `mesh-gui` | `mesh-bridge-gui.service` |

## Common Scenarios

### Scenario 1: Outdoor Installation with Thermal Protection

```bash
# Enable thermal management
icenet-services enable thermal
icenet-services start thermal

# Verify it's running
icenet-services status thermal
```

### Scenario 2: Mesh Network Node

```bash
# Enable Meshtastic bridge
icenet-services enable meshtastic
icenet-services start meshtastic

# Check logs
journalctl -u meshtastic-bridge -f
```

### Scenario 3: Desktop Mesh Configuration

```bash
# Enable GUI for configuration
icenet-services enable mesh-gui
icenet-services start mesh-gui
```

### Scenario 4: Disable All Extra Services

```bash
# Disable everything (minimal system)
icenet-services disable thermal
icenet-services disable meshtastic
icenet-services disable mesh-gui
```

## Automation

Services can be controlled in scripts:

```bash
#!/bin/bash
# Enable services based on environment

if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp_c=$((temp / 1000))

    if [ $temp_c -lt 15 ]; then
        echo "Cold environment detected, enabling thermal management"
        icenet-services enable thermal
        icenet-services start thermal
    fi
fi

# Check for Meshtastic hardware
if lsusb | grep -q "Meshtastic"; then
    echo "Meshtastic device found, enabling bridge"
    icenet-services enable meshtastic
    icenet-services start meshtastic
fi
```

## Integration with Systemd

All services are standard systemd units and can be controlled with systemctl:

```bash
# Direct systemd control
sudo systemctl enable icenet-thermal
sudo systemctl start icenet-thermal
sudo systemctl status icenet-thermal
sudo systemctl stop icenet-thermal
sudo systemctl disable icenet-thermal

# View logs
journalctl -u icenet-thermal
journalctl -u meshtastic-bridge -f
```

The Service Manager is a convenient wrapper around systemd that:
- Provides user-friendly names
- Uses polkit for privilege escalation (no sudo needed in GUI)
- Shows status in plain language
- Handles multiple services easily

## Configuration Files

Service configuration files:
- `/etc/systemd/system/icenet-thermal.service`
- `/etc/systemd/system/meshtastic-bridge.service`
- `/etc/systemd/system/mesh-bridge-gui.service`

Service binaries:
- `/opt/icenet-thermal/thermal-manager.sh`
- `/opt/meshtastic-bridge/bridge.py`
- `/opt/mesh-bridge-gui/mesh-bridge-gui.py`

## Troubleshooting

### Service won't start

Check logs:
```bash
journalctl -u <service-name> -n 50
```

Check service status:
```bash
systemctl status <service-name>
```

### Permission errors

The GUI uses polkit for authentication. If you see errors, try CLI with sudo:
```bash
sudo systemctl start <service-name>
```

### Service enabled but not running after reboot

Check if service has any dependencies:
```bash
systemctl list-dependencies <service-name>
```

Check boot logs:
```bash
journalctl -b | grep <service-name>
```

## Advanced Usage

### Creating Custom Services

Add your own services to the Service Manager by:

1. Creating systemd service file in `/etc/systemd/system/`
2. Adding entry to `SERVICES` array in `/usr/local/bin/icenet-services`
3. Adding service card to GUI in `icenet-service-manager.py`

Example custom service entry:
```bash
SERVICES["myservice"]="my-custom.service|My Custom Service|Description here"
```

## Security Notes

- Services run with standard user privileges unless specified
- GUI uses polkit for privilege escalation (authenticated sudo)
- CLI requires sudo for enable/disable/start/stop operations
- All services are disabled by default for security

## Installation

The Service Manager is pre-installed on all IceNet-OS ISO images and installations. No manual installation needed.

For manual installation:
```bash
cd /path/to/IceNet-OS/integrations/service-manager
sudo ./install-service-manager.sh
```

## Support

- GitHub: https://github.com/IceNet-01/IceNet-OS
- Documentation: See IceNet-OS docs/ directory
- Service logs: `journalctl -u <service-name>`

## License

MIT License - Same as IceNet-OS
