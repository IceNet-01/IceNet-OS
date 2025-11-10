# IceNet-OS Meshtastic Bridge GUI Integration

Desktop application for managing Meshtastic radio bridge relay stations on IceNet-OS.

## Overview

The Mesh Bridge GUI provides a visual interface for configuring and monitoring Meshtastic radio bridges. It enables bidirectional message forwarding between multiple USB-connected radios with real-time monitoring and analytics.

## Features

- **Visual Configuration**: Drag-and-drop bridge route creation
- **Multi-Radio Support**: Manage 2+ Meshtastic devices simultaneously
- **Real-Time Monitoring**: Live dashboard with statistics and metrics
- **Message Deduplication**: Prevents loops and duplicate messages
- **Auto-Reconnection**: Automatic recovery from connection losses
- **Analytics Dashboard**: Traffic visualization, signal strength, battery monitoring

## Installation

### Via Package Manager (Recommended)
```bash
ice-pkg install mesh-bridge-gui
```

### Manual Installation
```bash
cd /opt/icenet/mesh-bridge-gui
sudo ./install.sh
```

## Launching the Application

### GUI Mode (Default)
```bash
mesh-bridge-gui
```

### From Application Menu
After installation, find "Mesh Bridge" in your application launcher.

## Hardware Requirements

- **USB Ports**: 2+ available for Meshtastic radios
- **Memory**: 512MB RAM minimum
- **Display**: GUI requires X11 or Wayland
- **OS**: IceNet-OS with GUI components installed

## Configuration

### Initial Setup

1. Connect Meshtastic radios via USB
2. Launch Mesh Bridge GUI
3. Radios will auto-detect and appear in the device list
4. Click "Add Bridge Route" to create forwarding rules
5. Configure source and destination radios
6. Enable the route and save

### Bridge Routes

Create multiple bridge routes for complex topologies:

```
Radio A (VHF) ←→ Radio B (UHF)
Radio B (UHF) ←→ Radio C (LoRa)
Radio C (LoRa) ←→ Radio A (VHF)
```

### Configuration File

Located at `~/.config/icenet/mesh-bridge.json`:

```json
{
  "routes": [
    {
      "name": "VHF to UHF Bridge",
      "source": "/dev/ttyUSB0",
      "target": "/dev/ttyUSB1",
      "enabled": true,
      "dedup_window": 600
    }
  ],
  "reconnect_delay": 5,
  "log_level": "info"
}
```

## Dashboard Features

### Main View
- Connected radios with signal strength
- Active bridge routes
- Message throughput graphs
- Error and warning indicators

### Statistics Panel
- Messages sent/received per radio
- Deduplication rate
- Error counts
- Uptime per route

### Radio Details
- Battery level
- Signal strength (SNR)
- Channel utilization
- Firmware version

### Logs Tab
- Real-time message log
- Filterable by radio or message type
- Export capability

## Use Cases

### Desktop Bridge Station
```bash
# Launch GUI for interactive management
mesh-bridge-gui
```

### Dual-Radio Relay
Connect VHF radio to computer, configure bridge to UHF radio, monitor traffic in real-time.

### Development and Testing
Use GUI to test bridge configurations before deploying headless version.

## Integration with Headless Mode

The GUI can export configurations compatible with the headless bridge:

```bash
# Export configuration
mesh-bridge-gui --export-config bridge-config.json

# Use with headless bridge
meshtastic-bridge --config bridge-config.json
```

## Troubleshooting

### Radios Not Detected
```bash
# Check USB connections
lsusb | grep "Future Technology Devices"

# Check permissions
ls -l /dev/ttyUSB*

# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in
```

### GUI Won't Start
```bash
# Check display server
echo $DISPLAY

# Verify GUI packages installed
ice-pkg list | grep gui

# Check logs
journalctl --user -u mesh-bridge-gui
```

### Connection Drops
```bash
# Check USB power management
cat /sys/bus/usb/devices/*/power/autosuspend

# Disable USB autosuspend
echo -1 | sudo tee /sys/bus/usb/devices/*/power/autosuspend

# Use powered USB hub for multiple radios
```

### High CPU Usage
```bash
# Check message rate
# High message volumes increase processing load

# Adjust deduplication window
# Shorter windows reduce memory/CPU usage
```

## Command Line Options

```bash
mesh-bridge-gui [options]

Options:
  --config <file>     Load configuration from file
  --export-config <file>  Export current config and exit
  --headless          Run without GUI (launches daemon)
  --log-level <level> Set logging level (debug, info, warn, error)
  --version           Show version information
  --help              Display help
```

## Performance

- **Memory**: ~150-250MB typical
- **CPU**: <5% idle, 10-20% under load
- **Disk**: <50MB installation size
- **Network**: USB serial only, no network access required

## Security

- No network listening ports
- USB serial communication only
- User-level permissions (dialout group)
- Isolated process space
- Configuration files readable only by owner

## Updating

```bash
# Via package manager
ice-pkg update
ice-pkg upgrade mesh-bridge-gui

# Manual update
cd /opt/icenet/mesh-bridge-gui
git pull
npm install
npm run build
```

## Uninstallation

```bash
# Via package manager
ice-pkg remove mesh-bridge-gui

# Manual removal
sudo rm -rf /opt/icenet/mesh-bridge-gui
sudo rm /usr/local/bin/mesh-bridge-gui
rm -rf ~/.config/icenet/mesh-bridge.json
```

## Related Tools

- **meshtastic-bridge**: Headless version for server deployments
- **icenet-network**: Network configuration for internet bridging
- **thermal-mgmt**: Thermal management for outdoor installations

## Source

Integrated from: https://github.com/IceNet-01/Mesh-Bridge-GUI

## Dependencies

- Node.js 18+
- Electron
- Meshtastic Python library
- USB serial drivers

## License

See source repository for license information.
