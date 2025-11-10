# IceNet-OS Desktop Environment

Lightweight graphical desktop environment for IceNet-OS with taskbar, start menu, and full application integration.

## Overview

IceNet-Desktop provides a complete graphical user interface optimized for embedded systems and low-resource environments. It includes:

- **Xorg Display Server**: X11 for graphics
- **Openbox Window Manager**: Lightweight, fast window management
- **tint2 Panel**: Modern taskbar with system tray
- **jgmenu Start Menu**: Hierarchical application launcher
- **Custom Theme**: IceNet branded appearance
- **Application Integration**: All utilities and integrated software have GUI entries

## Features

- **Lightweight**: ~100MB RAM usage idle
- **Fast**: Sub-second application launch
- **Complete**: Taskbar, start menu, system tray, notifications
- **Integrated**: All IceNet-OS software has menu entries and icons
- **Customizable**: Easy theme and configuration customization
- **Touch Friendly**: Optional touch-optimized interface for tablets

## System Requirements

- **Memory**: 512MB RAM minimum (1GB recommended)
- **Storage**: ~200MB for desktop environment
- **Display**: Any resolution supported, optimized for 1920x1080
- **Graphics**: Any GPU with basic X11 support
- **Input**: Keyboard and mouse (or touchscreen)

## Installation

### Quick Install
```bash
cd integrations
sudo ./install-integrations.sh --desktop
```

### Manual Installation
```bash
cd integrations/icenet-desktop
sudo ./install-desktop.sh
```

### What Gets Installed

**Core Components**:
- Xorg display server
- Openbox window manager
- tint2 panel (taskbar)
- jgmenu start menu
- LightDM display manager (login screen)
- Nitrogen wallpaper manager
- Picom compositor (optional transparency/effects)

**Applications**:
- PCManFM file manager
- LXTerminal terminal emulator
- Mousepad text editor
- Custom network manager applet
- System monitor applet

## Starting the Desktop

### Auto-Start (Default)
Desktop starts automatically after login when enabled:
```bash
sudo systemctl enable lightdm
```

### Manual Start
```bash
# From console, start X session
startx
```

### Switch to Console
```bash
# Press Ctrl+Alt+F2 for console
# Press Ctrl+Alt+F7 to return to GUI
```

## Desktop Layout

### Taskbar (tint2)
Located at bottom of screen:
```
[Start Menu] [Application Shortcuts] [Task Buttons] [System Tray] [Clock]
```

**Components**:
- **Start Menu Button**: Click to open application menu
- **Quick Launch**: Pin your favorite apps
- **Task Buttons**: Running applications
- **System Tray**: Network, sound, notifications
- **Clock**: Current time and date

### Start Menu (jgmenu)

Hierarchical menu structure:
```
IceNet-OS
├── Network Tools
│   ├── Ping (Network Connectivity Test)
│   ├── Network Statistics
│   ├── Download Manager
│   ├── Network Configuration
│   └── Mesh Bridge GUI
├── System Tools
│   ├── System Monitor (Top)
│   ├── Task Manager
│   ├── System Information
│   ├── Thermal Management GUI
│   └── Disk Usage
├── Utilities
│   ├── File Manager
│   ├── Text Editor
│   ├── Terminal
│   └── Calculator
├── Settings
│   ├── Display Settings
│   ├── Network Settings
│   ├── Theme Settings
│   └── System Settings
└── Exit
    ├── Lock Screen
    ├── Log Out
    ├── Reboot
    └── Shutdown
```

### Desktop Right-Click Menu
Right-click anywhere on desktop for:
- Terminal
- File Manager
- Settings
- Refresh Desktop
- System Information

## Configuration

### Panel Configuration
Edit `~/.config/tint2/tint2rc`:
```ini
# Panel position (bottom, top, left, right)
panel_position = bottom center horizontal

# Panel size
panel_size = 100% 40

# Background
background_color = #1a1a1a 90
```

### Start Menu Configuration
Edit `~/.config/jgmenu/jgmenurc`:
```ini
# Position and size
menu_width = 300
menu_height = 500

# Theme
color_menu_bg = 26 26 26 90
color_norm_fg = 220 220 220 100
```

### Window Manager Configuration
Edit `~/.config/openbox/rc.xml`:
```xml
<!-- Keyboard shortcuts -->
<keybind key="W-d">
  <action name="ToggleShowDesktop"/>
</keybind>
```

### Appearance Settings

**Wallpaper**:
```bash
nitrogen --set-zoom-fill /usr/share/backgrounds/icenet/default.jpg
```

**Theme**:
```bash
# GTK theme
lxappearance
# Select "IceNet-Dark" or "IceNet-Light"
```

**Icon Theme**:
```bash
# Icons automatically use Papirus theme
# Change in lxappearance if desired
```

## Application Integration

All IceNet-OS software has desktop integration:

### Network Utilities
- **Ping Tool**: `icenet-ping-gui` - Graphical ping utility
- **Network Stats**: `icenet-netstat-gui` - Network monitor
- **Download Manager**: `icedownload-gui` - Download manager with queue
- **Network Config**: `icenet-network-gui` - Visual network configuration

### System Monitoring
- **System Monitor**: `icetop` - Process monitor (launches in terminal)
- **Task Manager**: `icenet-taskman` - Graphical task manager
- **System Info**: `icenet-sysinfo-gui` - System information panel
- **Disk Usage**: `icedf-gui` - Disk space analyzer

### Integrated Software
- **Thermal Management**: `icenet-thermal-gui` - Temperature control panel
- **Mesh Bridge GUI**: `mesh-bridge-gui` - Radio bridge configuration
- **Meshtastic Bridge Status**: `meshtastic-bridge-status` - Bridge monitor

### Standard Applications
- **File Manager**: `pcmanfm` - Browse files
- **Terminal**: `lxterminal` - Command line
- **Text Editor**: `mousepad` - Edit text files
- **Calculator**: `galculator` - Calculate

## Keyboard Shortcuts

### Window Management
- `Super + D`: Show/hide desktop
- `Alt + Tab`: Switch between windows
- `Alt + F4`: Close window
- `Super + Left`: Snap window to left half
- `Super + Right`: Snap window to right half
- `Super + Up`: Maximize window
- `Alt + Space`: Window menu

### Applications
- `Super + T`: Terminal
- `Super + E`: File manager
- `Super + R`: Run dialog
- `Super + L`: Lock screen
- `Print`: Screenshot

### System
- `Ctrl + Alt + Delete`: Task manager
- `Ctrl + Alt + Backspace`: Restart X server (emergency)

## Themes

### IceNet-Dark (Default)
- Dark panel with transparency
- Blue accent color (#3498db)
- Dark window decorations
- Optimized for low-light environments

### IceNet-Light
- Light panel
- Bright theme for outdoor use
- High contrast
- Easy readability in sunlight

### Custom Themes
```bash
# Install custom theme
cp -r my-theme ~/.themes/
lxappearance  # Select theme
```

## Display Manager (Login Screen)

### LightDM Configuration
Edit `/etc/lightdm/lightdm.conf`:
```ini
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=icenet-desktop
autologin-user=your-username
```

### Auto-Login
```bash
sudo icenet-desktop-config --autologin enable
```

### Custom Login Background
```bash
sudo cp wallpaper.jpg /usr/share/backgrounds/icenet/login.jpg
```

## Performance Tuning

### Reduce Memory Usage
Edit `~/.config/icenet-desktop/settings`:
```ini
# Disable compositor
compositor_enabled=false

# Reduce panel size
panel_height=32

# Disable desktop icons
desktop_icons=false
```

### Optimize for Low-End Hardware
```bash
# Use software rendering
export LIBGL_ALWAYS_SOFTWARE=1

# Disable animations
gsettings set org.gnome.desktop.interface enable-animations false
```

### Optimize for Touch Screens
```bash
# Larger click targets
icenet-desktop-config --touch-mode enable

# Larger fonts
icenet-desktop-config --font-size 12
```

## Troubleshooting

### Desktop Won't Start
```bash
# Check Xorg logs
cat /var/log/Xorg.0.log

# Test X server
startx

# Check display manager
sudo systemctl status lightdm
```

### No Taskbar
```bash
# Restart tint2
killall tint2
tint2 &

# Check configuration
cat ~/.config/tint2/tint2rc
```

### Start Menu Not Working
```bash
# Restart jgmenu
killall jgmenu
jgmenu &

# Regenerate menu
jgmenu_run init
```

### Slow Performance
```bash
# Check resource usage
icetop

# Disable compositor
killall picom

# Reduce visual effects
icenet-desktop-config --performance-mode
```

### Display Resolution Wrong
```bash
# List available resolutions
xrandr

# Set resolution
xrandr --output HDMI-1 --mode 1920x1080

# Make permanent
echo "xrandr --output HDMI-1 --mode 1920x1080" >> ~/.config/openbox/autostart
```

## Advanced Configuration

### Multi-Monitor Setup
```bash
# Detect monitors
xrandr

# Configure layout
xrandr --output HDMI-1 --primary --mode 1920x1080 \
       --output VGA-1 --right-of HDMI-1 --mode 1920x1080
```

### Custom Keyboard Shortcuts
Edit `~/.config/openbox/rc.xml`:
```xml
<keybind key="W-b">
  <action name="Execute">
    <command>firefox</command>
  </action>
</keybind>
```

### Startup Applications
Edit `~/.config/openbox/autostart`:
```bash
#!/bin/bash
# Start applications on login

# Network manager applet
nm-applet &

# Volume control
volumeicon &

# Compositor (optional)
picom &

# Wallpaper
nitrogen --restore &
```

### Remote Desktop Access
```bash
# Install x11vnc
ice-pkg install x11vnc

# Start VNC server
x11vnc -display :0 -auth ~/.Xauthority

# Connect from remote
vncviewer server-ip:5900
```

## Desktop Entry Format

All applications follow FreeDesktop.org standard:

Example: `/usr/share/applications/icenet-ping.desktop`
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Network Ping Tool
Comment=Test network connectivity with ICMP ping
Exec=icenet-ping-gui
Icon=network-ping
Terminal=false
Categories=Network;System;
Keywords=ping;network;connectivity;
StartupNotify=true
```

## Creating Custom Launchers

```bash
# Create launcher in menu
cat > ~/.local/share/applications/my-app.desktop <<EOF
[Desktop Entry]
Name=My Application
Exec=/path/to/my-app
Icon=application-default-icon
Terminal=false
Categories=Utility;
EOF

# Create desktop shortcut
cp ~/.local/share/applications/my-app.desktop ~/Desktop/
chmod +x ~/Desktop/my-app.desktop
```

## Resource Usage

**Idle Desktop**:
- Memory: ~100-150MB
- CPU: <1%
- Disk: ~200MB

**With Applications**:
- +30MB per terminal
- +50MB per file manager window
- +100MB per GUI application

**Minimal Installation** (no desktop):
- Memory: <50MB
- Perfect for headless servers

## Comparison: Desktop vs Headless

| Feature | Desktop | Headless |
|---------|---------|----------|
| Memory | ~150MB | <50MB |
| Disk Space | ~200MB | ~50MB |
| Boot Time | +2-3s | Faster |
| User Interface | GUI | CLI only |
| Remote Access | VNC/RDP | SSH only |
| Ease of Use | High | Requires CLI knowledge |
| Best For | Desktop use | Servers, remote nodes |

## Uninstallation

### Disable GUI
```bash
# Stop display manager
sudo systemctl stop lightdm
sudo systemctl disable lightdm

# System will boot to console
```

### Remove Desktop Environment
```bash
# Uninstall packages
ice-pkg remove icenet-desktop

# Remove configuration
rm -rf ~/.config/tint2 ~/.config/jgmenu ~/.config/openbox
```

### Keep Core, Remove GUI
```bash
# Selective removal
ice-pkg remove tint2 jgmenu lightdm

# Keep terminal utilities
# System remains functional via SSH
```

## Integration with IceNet-OS

### Service Management
Desktop applications can control services:
```bash
# GUI service manager shows:
# - icenet-thermal
# - meshtastic-bridge
# - Network services
# With start/stop/restart buttons
```

### Network Configuration
Visual network manager integrates with `icenet-network`:
```bash
# GUI wraps CLI tools
# Changes saved to /etc/network/interfaces
# Compatible with CLI configuration
```

### System Monitoring
GUI tools use same backend as CLI:
```bash
# icetop-gui reads same /proc data
# Results identical to CLI version
# Can switch between GUI and CLI anytime
```

## Updates

```bash
# Update desktop environment
ice-pkg update
ice-pkg upgrade icenet-desktop

# Or manually
cd /opt/icenet/icenet-desktop
git pull
sudo ./install-desktop.sh --update
```

## Source

Part of IceNet-OS integrated components.

## License

See IceNet-OS LICENSE file.
