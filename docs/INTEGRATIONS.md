# IceNet-OS Integrated Software Guide

IceNet-OS includes native integration for specialized software components designed for embedded, remote, and mesh networking applications.

## Overview

Three integrated software components extend IceNet-OS capabilities:

1. **Thermal Management System** - Automatic CPU-based heating for cold environments
2. **Meshtastic Bridge (Headless)** - Production radio bridge service
3. **Mesh Bridge GUI** - Desktop application for bridge configuration

All components are:
- **Optional**: Install and enable only what you need
- **Integrated**: Work seamlessly with IceNet-OS services
- **Optimized**: Minimal resource usage, maximum reliability
- **Documented**: Comprehensive guides included

## Quick Installation

### Install All Integrations
```bash
cd integrations
sudo ./install-integrations.sh --all
```

### Install Individual Components
```bash
# Thermal management only
sudo ./install-integrations.sh --thermal

# Meshtastic bridge only
sudo ./install-integrations.sh --bridge

# GUI only
sudo ./install-integrations.sh --gui
```

### Via Package Manager (Future)
```bash
# When packages are available
ice-pkg install thermal-mgmt
ice-pkg install meshtastic-bridge
ice-pkg install mesh-bridge-gui
```

## Component Details

### 1. Thermal Management System

**Purpose**: Prevents equipment freezing in cold environments using automatic CPU heating.

**Use Cases**:
- Outdoor tower installations
- Remote repeater stations
- Unheated enclosures
- Cold weather deployments

**Installation**:
```bash
sudo ./install-integrations.sh --thermal
```

**Enable and Start**:
```bash
sudo systemctl enable --now icenet-thermal
```

**Monitor**:
```bash
# View status
icenet-thermal status

# GUI dashboard (optional)
sudo icenet-thermal-gui

# Check logs
journalctl -u icenet-thermal -f
```

**Configuration**: `/etc/icenet/thermal-mgmt.conf`

**Documentation**: [integrations/thermal-mgmt/README.md](../integrations/thermal-mgmt/README.md)

### 2. Meshtastic Bridge (Headless)

**Purpose**: Forwards messages between Meshtastic radios without GUI, perfect for servers and remote installations.

**Use Cases**:
- Dedicated relay stations
- Remote repeaters
- Always-on bridge servers
- Raspberry Pi deployments

**Installation**:
```bash
sudo ./install-integrations.sh --bridge
```

**Enable and Start** (Optional - Disabled by Default):
```bash
# Enable for automatic start
sudo systemctl enable meshtastic-bridge

# Start immediately
sudo systemctl start meshtastic-bridge
```

**Monitor**:
```bash
# View status
icenet-bridge status

# Check JSON status file
cat /var/lib/icenet/meshtastic-bridge/status.json

# View logs
journalctl -u meshtastic-bridge -f
```

**Configuration**: `/etc/icenet/meshtastic-bridge.conf`

**Documentation**: [integrations/meshtastic-bridge/README.md](../integrations/meshtastic-bridge/README.md)

**Important**: This service is **disabled by default**. Enable it only when you need bridge functionality.

### 3. Mesh Bridge GUI

**Purpose**: Visual desktop application for configuring and monitoring Meshtastic radio bridges.

**Use Cases**:
- Desktop bridge stations
- Interactive configuration
- Development and testing
- Real-time monitoring

**Installation**:
```bash
sudo ./install-integrations.sh --gui
```

**Launch**:
```bash
# From command line
mesh-bridge-gui

# Or from application menu
# Look for "Meshtastic Bridge GUI"
```

**Features**:
- Visual bridge route configuration
- Real-time traffic monitoring
- Signal strength and battery indicators
- Message log viewer
- Export configurations for headless deployment

**Documentation**: [integrations/mesh-bridge-gui/README.md](../integrations/mesh-bridge-gui/README.md)

## Integration Architecture

### Service Hierarchy

```
IceNet-OS Init (PID 1)
├── System Services
│   ├── Network
│   ├── SSH
│   └── Logging
├── Optional Integrations
│   ├── icenet-thermal (auto-heating)
│   └── meshtastic-bridge (radio bridge)
└── User Applications
    └── mesh-bridge-gui (when launched)
```

### File Locations

**Binaries**:
- `/usr/bin/icenet-thermal-daemon`
- `/usr/bin/icenet-thermal-gui`
- `/usr/bin/meshtastic-bridge-daemon`
- `/usr/bin/mesh-bridge-gui`

**Source Code**:
- `/opt/icenet/thermal-mgmt/`
- `/opt/icenet/meshtastic-bridge/`
- `/opt/icenet/mesh-bridge-gui/`

**Configuration**:
- `/etc/icenet/thermal-mgmt.conf`
- `/etc/icenet/meshtastic-bridge.conf`
- `~/.config/icenet/mesh-bridge.json` (GUI)

**Runtime Data**:
- `/var/lib/icenet/thermal/`
- `/var/lib/icenet/meshtastic-bridge/`

**Systemd Services**:
- `/etc/systemd/system/icenet-thermal.service`
- `/etc/systemd/system/meshtastic-bridge.service`

## Common Deployment Scenarios

### Scenario 1: Remote Outdoor Repeater

**Hardware**: Raspberry Pi 4, 2x Meshtastic radios, outdoor enclosure

**Installation**:
```bash
# Install IceNet-OS
# Install both thermal management and bridge
cd integrations
sudo ./install-integrations.sh --thermal
sudo ./install-integrations.sh --bridge

# Configure network
sudo icenet-network static eth0 192.168.1.10 255.255.255.0 192.168.1.1

# Enable services
sudo systemctl enable icenet-thermal
sudo systemctl enable meshtastic-bridge

# Start services
sudo systemctl start icenet-thermal
sudo systemctl start meshtastic-bridge

# Verify operation
icenet-thermal status
icenet-bridge status
```

**Monitoring**:
```bash
# SSH from remote location
ssh user@192.168.1.10

# Check status
sysinfo
journalctl -u meshtastic-bridge -f
journalctl -u icenet-thermal -f
```

### Scenario 2: Desktop Bridge Station

**Hardware**: Desktop/laptop with USB ports, 2+ Meshtastic radios

**Installation**:
```bash
# Install GUI only
cd integrations
sudo ./install-integrations.sh --gui

# Launch application
mesh-bridge-gui
```

**Usage**:
1. Connect radios via USB
2. Launch Mesh Bridge GUI
3. Configure bridge routes visually
4. Monitor traffic in real-time
5. Export config for headless deployment

### Scenario 3: Multi-Purpose System

**Hardware**: Zima board or similar, multiple roles

**Installation**:
```bash
# Install all components
cd integrations
sudo ./install-integrations.sh --all

# Enable only thermal management by default
sudo systemctl enable icenet-thermal

# Bridge is available but disabled
# Enable manually when needed:
# sudo systemctl enable meshtastic-bridge
```

**Flexibility**:
- Thermal management always active (protection)
- Bridge service available but optional
- GUI available for configuration when needed
- Can enable/disable services without reinstallation

### Scenario 4: Development and Testing

**Hardware**: Any IceNet-OS compatible system

**Installation**:
```bash
# Install all for testing
cd integrations
sudo ./install-integrations.sh --all

# Test thermal management
sudo icenet-thermal-gui

# Test bridge headless
sudo meshtastic-bridge-daemon --foreground --debug

# Test GUI
mesh-bridge-gui

# Once tested, enable desired services
sudo systemctl enable icenet-thermal
sudo systemctl enable meshtastic-bridge
```

## Resource Usage

### Thermal Management
- **Memory**: ~50MB
- **CPU**: <1% idle, 70% when heating
- **Disk**: ~20MB
- **Dependencies**: Python 3.8+, Textual, NumPy

### Meshtastic Bridge (Headless)
- **Memory**: ~50-100MB
- **CPU**: <2% average
- **Disk**: ~15MB
- **Dependencies**: Python 3.8+, meshtastic, pyserial, rich

### Mesh Bridge GUI
- **Memory**: ~150-250MB
- **CPU**: 5-20% active use
- **Disk**: ~50MB
- **Dependencies**: Node.js 18+, Electron, React

### Combined System
Total overhead with all services running:
- **Memory**: ~300-400MB
- **CPU**: <10% typical (excluding heating)
- **Disk**: ~100MB

## Service Management

### Enable Services at Boot
```bash
# Thermal management
sudo systemctl enable icenet-thermal

# Meshtastic bridge
sudo systemctl enable meshtastic-bridge
```

### Disable Services
```bash
sudo systemctl disable icenet-thermal
sudo systemctl disable meshtastic-bridge
```

### Start/Stop Services
```bash
# Start
sudo systemctl start icenet-thermal
sudo systemctl start meshtastic-bridge

# Stop
sudo systemctl stop icenet-thermal
sudo systemctl stop meshtastic-bridge

# Restart
sudo systemctl restart icenet-thermal
sudo systemctl restart meshtastic-bridge
```

### Check Status
```bash
# Detailed status
sudo systemctl status icenet-thermal
sudo systemctl status meshtastic-bridge

# Quick check all services
systemctl list-units 'icenet-*' --all
```

### View Logs
```bash
# Follow logs in real-time
journalctl -u icenet-thermal -f
journalctl -u meshtastic-bridge -f

# View recent logs
journalctl -u icenet-thermal --since "1 hour ago"
journalctl -u meshtastic-bridge --since "1 hour ago"

# All IceNet services
journalctl -u 'icenet-*' -f
```

## Configuration Management

### Thermal Management
Edit `/etc/icenet/thermal-mgmt.conf`:
```ini
[thermal]
heat_threshold = 0.0      # Start heating at 0°C
stop_threshold = 5.0      # Stop heating at 5°C
cpu_load_percent = 70     # CPU load during heating
check_interval = 10       # Check every 10 seconds
```

### Meshtastic Bridge
Edit `/etc/icenet/meshtastic-bridge.conf`:
```ini
[bridge]
auto_detect = true
dedup_window_seconds = 600
reconnect_min_delay = 2
reconnect_max_delay = 32
```

### Apply Configuration Changes
```bash
# Restart service to apply changes
sudo systemctl restart icenet-thermal
sudo systemctl restart meshtastic-bridge
```

## Monitoring and Health Checks

### System-Wide Status
```bash
# IceNet system info includes integration status
sysinfo

# View all services
systemctl list-units 'icenet-*'
```

### Thermal Management Status
```bash
# Command line status
icenet-thermal status

# GUI dashboard
sudo icenet-thermal-gui

# Current temperature
cat /sys/class/thermal/thermal_zone0/temp
```

### Bridge Status
```bash
# Command line status
icenet-bridge status

# JSON status file
cat /var/lib/icenet/meshtastic-bridge/status.json | jq

# Connected radios
lsusb | grep "Future Technology"
```

### Automated Monitoring
```bash
# Create monitoring script
cat > /usr/local/bin/icenet-monitor <<'EOF'
#!/bin/bash
echo "=== IceNet-OS Integration Status ==="
systemctl is-active icenet-thermal && echo "Thermal: Active" || echo "Thermal: Inactive"
systemctl is-active meshtastic-bridge && echo "Bridge: Active" || echo "Bridge: Inactive"
echo ""
icenet-thermal status 2>/dev/null || echo "Thermal: Not configured"
icenet-bridge status 2>/dev/null || echo "Bridge: Not configured"
EOF

chmod +x /usr/local/bin/icenet-monitor

# Run monitoring
icenet-monitor
```

## Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status icenet-thermal
sudo systemctl status meshtastic-bridge

# View detailed logs
journalctl -xe -u icenet-thermal
journalctl -xe -u meshtastic-bridge

# Check configuration
cat /etc/icenet/thermal-mgmt.conf
cat /etc/icenet/meshtastic-bridge.conf
```

### Dependencies Missing
```bash
# Reinstall dependencies
cd /opt/icenet/thermal-mgmt
pip3 install -r requirements.txt

cd /opt/icenet/meshtastic-bridge
pip3 install meshtastic pyserial rich
```

### Permission Issues
```bash
# Fix permissions
sudo chown -R root:root /opt/icenet/thermal-mgmt
sudo chown -R meshtastic-bridge:dialout /opt/icenet/meshtastic-bridge

# Verify user groups
groups meshtastic-bridge
```

### USB Device Access
```bash
# Check USB devices
lsusb

# Check serial ports
ls -l /dev/ttyUSB*

# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in
```

## Updating Integrations

### Manual Updates
```bash
# Update thermal management
cd /opt/icenet/thermal-mgmt
git pull
pip3 install -r requirements.txt
sudo systemctl restart icenet-thermal

# Update bridge
cd /opt/icenet/meshtastic-bridge
git pull
pip3 install -r requirements.txt
sudo systemctl restart meshtastic-bridge

# Update GUI
cd /opt/icenet/mesh-bridge-gui
git pull
npm install
npm run build
```

### Via Package Manager (Future)
```bash
ice-pkg update
ice-pkg upgrade thermal-mgmt meshtastic-bridge mesh-bridge-gui
```

## Uninstallation

### Stop and Disable Services
```bash
sudo systemctl stop icenet-thermal meshtastic-bridge
sudo systemctl disable icenet-thermal meshtastic-bridge
```

### Remove Files
```bash
# Remove binaries
sudo rm /usr/bin/icenet-thermal-daemon
sudo rm /usr/bin/icenet-thermal-gui
sudo rm /usr/bin/meshtastic-bridge-daemon
sudo rm /usr/bin/mesh-bridge-gui

# Remove source
sudo rm -rf /opt/icenet/thermal-mgmt
sudo rm -rf /opt/icenet/meshtastic-bridge
sudo rm -rf /opt/icenet/mesh-bridge-gui

# Remove configuration (optional)
sudo rm /etc/icenet/thermal-mgmt.conf
sudo rm /etc/icenet/meshtastic-bridge.conf
rm -rf ~/.config/icenet/mesh-bridge.json

# Remove systemd services
sudo rm /etc/systemd/system/icenet-thermal.service
sudo rm /etc/systemd/system/meshtastic-bridge.service
sudo systemctl daemon-reload
```

### Remove Service User
```bash
sudo userdel meshtastic-bridge
```

## Best Practices

### Security
- Run services with minimal privileges
- Keep software updated
- Monitor logs for anomalies
- Use secure SSH for remote management

### Reliability
- Enable auto-start for critical services
- Configure automatic reconnection
- Monitor health check files
- Set up remote monitoring

### Resource Management
- Disable unused services
- Adjust CPU load for thermal management
- Configure appropriate deduplication windows
- Monitor memory usage

### Documentation
- Document your configuration
- Keep notes on customizations
- Track enabled services
- Record deployment dates

## Integration with IceNet-OS Features

### With Network Configuration
```bash
# Configure static IP for remote access
icenet-network static eth0 192.168.1.10 255.255.255.0 192.168.1.1

# Enable SSH
ice-pkg install openssh
sudo systemctl enable sshd
```

### With System Monitoring
```bash
# All integrations appear in system monitoring
icetop          # Shows running services
icefree -h      # Memory usage
sysinfo         # Overall system status
```

### With Package Manager
```bash
# Future: All integrations installable via ice-pkg
ice-pkg search thermal
ice-pkg search meshtastic
ice-pkg install thermal-mgmt
```

## Support and Documentation

### Component Documentation
- [Thermal Management](../integrations/thermal-mgmt/README.md)
- [Meshtastic Bridge](../integrations/meshtastic-bridge/README.md)
- [Mesh Bridge GUI](../integrations/mesh-bridge-gui/README.md)

### Source Repositories
- [thermal-management-system](https://github.com/IceNet-01/thermal-management-system)
- [meshtastic-bridge-headless](https://github.com/IceNet-01/meshtastic-bridge-headless)
- [Mesh-Bridge-GUI](https://github.com/IceNet-01/Mesh-Bridge-GUI)

### IceNet-OS Documentation
- [Architecture](ARCHITECTURE.md)
- [Building](BUILDING.md)
- [Getting Started](GETTING_STARTED.md)
- [Utilities](UTILITIES.md)

## Contributing

To add new integrations or improve existing ones, see [CONTRIBUTING.md](../CONTRIBUTING.md).

Contribution areas:
- Additional integrations
- Package manager integration
- Automated testing
- Documentation improvements
- Bug fixes and enhancements

---

IceNet-OS Integrations provide powerful, optional functionality for specialized deployments while maintaining the core OS simplicity and reliability.
