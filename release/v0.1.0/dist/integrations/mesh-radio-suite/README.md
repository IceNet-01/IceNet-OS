# IceNet-OS Mesh & Radio Suite

Complete turnkey solution for mesh networking, LoRa communications, and SDR experimentation.

## Overview

This suite transforms IceNet-OS into a comprehensive platform for:
- **Mesh Networking**: Meshtastic, Reticulum, mesh routing protocols
- **LoRa Communications**: LoRaWAN, gateways, packet tools
- **Software Defined Radio**: Reception, transmission, analysis
- **Ham Radio**: Digital modes, APRS, weak signal communications

All integrated with desktop GUI, complete with icons and menu entries.

## Integrated Software

### Web Browser
**Microsoft Edge** (Chromium-based)
- Modern web rendering
- Hardware acceleration
- PDF reader built-in
- Privacy controls
- Developer tools

### Meshtastic Ecosystem

**Core Tools**:
- Meshtastic Python CLI - Command-line interface
- Meshtastic Flasher - Firmware management
- Meshtastic Web Interface - Browser-based configuration
- Meshtastic Serial Debug - Hardware debugging

**Features**:
- Device configuration and management
- Firmware updates (OTA and USB)
- Message sending/receiving
- Node monitoring
- Channel configuration
- Module settings

### Reticulum Stack

**Reticulum Network Stack**:
- Cryptographic mesh network protocol
- Runs over any medium (LoRa, packet radio, internet, sneakernet)
- End-to-end encrypted
- Forward secrecy
- Resilient routing

**NomadNet**:
- Terminal-based communications client
- Bulletin board system
- File transfers
- Real-time messaging
- Node administration
- Works offline

**Sideband**:
- Mobile-friendly messenger
- LXMF message format
- Asynchronous messaging
- Propagation nodes support
- Audio messages (optional)

**LXMF Tools**:
- Message propagation server
- Store and forward
- Message utilities

**RNode Utilities**:
- RNode firmware tools
- Hardware configuration
- Performance tuning

### LoRa Software Suite

**LoRaWAN Network Servers**:
- ChirpStack - Complete LoRaWAN network server
- The Things Stack - TTN/TTS compatibility
- LoRa Packet Forwarder - Gateway software

**Gateway Software**:
- sx1302_hal - For SX1302/SX1303 concentrators
- sx1301_hal - For SX1301 concentrators
- Picocell Gateway - Single channel gateway

**Development Tools**:
- PyLora - Python LoRa library
- RadioHead - Arduino library support
- LoRa modulation analysis tools

**Utilities**:
- Frequency planning tools
- Coverage mapping
- Link budget calculator
- Packet analyzer

### SDR Software Suite

**Reception & Analysis**:
- **GNU Radio** - The comprehensive SDR framework
  - GNU Radio Companion (visual flowgraph design)
  - Extensive block library
  - Custom module development

- **GQRX** - Spectrum analyzer and receiver
  - AM/FM/SSB/CW reception
  - Waterfall display
  - Recording capabilities

- **SDR++** - Modern cross-platform SDR software
  - Clean interface
  - Plugin system
  - Wide hardware support

- **SDRangel** - Multi-platform SDR software
  - Advanced features
  - Multiple RX/TX support
  - Extensive demodulators

- **CubicSDR** - Cross-platform SDR application
  - Easy to use
  - Good for beginners

- **OpenWebRX** - Web-based SDR receiver
  - No client software needed
  - Multiple simultaneous users
  - Shareable receiver

**Decoding & Analysis**:
- **dump1090** - ADS-B aircraft tracking
  - Real-time flight tracking
  - Web interface
  - JSON output

- **rtl_433** - ISM band signal decoder
  - Weather stations
  - Tire pressure sensors
  - Remote controls
  - Home automation

- **Inspectrum** - Signal analysis tool
  - Visual signal inspection
  - Symbol extraction
  - Reverse engineering

- **Universal Radio Hacker (URH)** - Protocol analysis
  - Signal investigation
  - Protocol reverse engineering
  - Fuzzing capabilities

**Ham Radio Digital Modes**:
- **fldigi** - Digital mode transceiver
  - PSK, RTTY, Olivia, etc.
  - Sound card modem
  - Logging integration

- **WSJT-X** - Weak signal communications
  - FT8, FT4, JT65, JT9
  - Meteor scatter
  - EME communications

- **direwolf** - APRS software modem
  - Packet radio TNC
  - IGate functionality
  - Digipeater

- **Xastir** - APRS client
  - Real-time mapping
  - Weather integration
  - Message handling

**Hardware Support Libraries**:
- **SoapySDR** - Hardware abstraction layer
  - Unified API for all SDRs
  - Plugin architecture

- **rtl-sdr** - RTL2832U support
  - DVB-T dongles as SDR
  - Wide frequency coverage (24-1766 MHz)

- **HackRF Tools** - HackRF One support
  - Half-duplex transceiver
  - 1 MHz - 6 GHz

- **LimeSDR Tools** - LimeSDR support
  - Full-duplex transceiver
  - MIMO capable

- **PlutoSDR Tools** - Analog Devices PlutoSDR
  - 325 MHz - 3.8 GHz
  - Full-duplex

**Transmission Tools**:
- **rpitx** - Raspberry Pi transmitter
  - Uses GPIO for RF generation
  - Multiple modes
  - No additional hardware

- **HackRF Transmission** - Full transmit support
- **LimeSDR TX** - High-power transmission
- **GNU Radio TX** - Custom transmission

### Mesh Networking Protocols

**Mesh Routing**:
- **Yggdrasil** - End-to-end encrypted IPv6 network
- **cjdns** - Encrypted networking protocol
- **Babel** - Loop-avoiding distance-vector routing
- **BATMAN-adv** - Better approach to mobile ad-hoc networking
- **OLSR** - Optimized Link State Routing

**Network Tools**:
- Mesh visualization tools
- Node discovery
- Route inspection
- Performance testing

## Installation

### Quick Install Everything
```bash
cd integrations
sudo ./install-integrations.sh --mesh-radio-suite
```

### Install Categories

```bash
# Browser only
sudo ./install-mesh-radio-suite.sh --browser

# Meshtastic tools
sudo ./install-mesh-radio-suite.sh --meshtastic

# Reticulum stack
sudo ./install-mesh-radio-suite.sh --reticulum

# LoRa suite
sudo ./install-mesh-radio-suite.sh --lora

# SDR suite
sudo ./install-mesh-radio-suite.sh --sdr

# Everything
sudo ./install-mesh-radio-suite.sh --all
```

## Desktop Integration

All software appears in start menu under organized categories:

```
Start Menu
├── Internet
│   └── Microsoft Edge
├── Mesh Networking
│   ├── Meshtastic
│   │   ├── Meshtastic CLI
│   │   ├── Meshtastic Flasher
│   │   ├── Meshtastic Web
│   │   └── Serial Debug
│   ├── Reticulum
│   │   ├── NomadNet
│   │   ├── Sideband
│   │   ├── RNode Config
│   │   └── LXMF Tools
│   └── Mesh Protocols
│       ├── Yggdrasil
│       ├── cjdns
│       └── Babel
├── LoRa Tools
│   ├── ChirpStack
│   ├── TTN Console
│   ├── Packet Forwarder
│   ├── Gateway Config
│   └── LoRa Utilities
└── SDR Tools
    ├── Reception
    │   ├── GQRX
    │   ├── SDR++
    │   ├── SDRangel
    │   ├── CubicSDR
    │   └── OpenWebRX
    ├── Analysis
    │   ├── GNU Radio Companion
    │   ├── Inspectrum
    │   ├── Universal Radio Hacker
    │   └── Signal Analyzer
    ├── Decoders
    │   ├── dump1090 (Aircraft)
    │   ├── rtl_433 (ISM Band)
    │   ├── APRS (direwolf)
    │   └── AIS Decoder
    └── Ham Radio
        ├── fldigi
        ├── WSJT-X
        ├── Xastir (APRS)
        └── FLRig
```

## Hardware Support

### Supported SDR Hardware
- RTL-SDR dongles (RTL2832U)
- HackRF One
- LimeSDR Mini/USB
- Analog Devices PlutoSDR
- Airspy Mini/R2/HF+
- SDRplay RSP series
- USRP (all models)
- BladeRF
- Red Pitaya

### Supported LoRa Hardware
- SX1276/77/78/79 modules
- SX1262/68 modules
- SX1302/1303 concentrators
- SX1301 concentrators
- RAK gateways
- Heltec boards
- TTGO boards
- LilyGO devices
- Meshtastic-compatible devices

### Supported Mesh Hardware
- Meshtastic nodes (ESP32, nRF52)
- RNode devices
- LoRa32 boards
- Raspberry Pi with LoRa HATs
- Custom LoRa hardware

## Common Use Cases

### 1. Meshtastic Node Management
```bash
# Launch Meshtastic GUI
meshtastic-gui

# CLI configuration
meshtastic --info
meshtastic --set lora.region US
meshtastic --sendtext "Hello mesh!"
```

### 2. Reticulum Mesh Network
```bash
# Start NomadNet
nomadnet

# Configure RNode
rnodeconf

# Run propagation node
lxmf-propagation
```

### 3. LoRaWAN Gateway
```bash
# Start ChirpStack
sudo systemctl start chirpstack-gateway-bridge
sudo systemctl start chirpstack-network-server

# Monitor packets
journalctl -fu chirpstack-gateway-bridge
```

### 4. SDR Reception
```bash
# Launch GQRX
gqrx

# Or SDR++
sdrpp

# Or GNU Radio
gnuradio-companion
```

### 5. Aircraft Tracking
```bash
# Start dump1090
dump1090-mutability --interactive --net

# Open browser to http://localhost:8080
```

### 6. Ham Radio Digital Modes
```bash
# Start fldigi
fldigi

# Or WSJT-X for FT8
wsjtx
```

## Configuration Examples

### Meshtastic Basic Setup
```bash
# Connect to device
meshtastic --port /dev/ttyUSB0

# Set region
meshtastic --set lora.region US

# Set node name
meshtastic --set-owner "IceNet Node"

# Configure channel
meshtastic --ch-set name "IceNet-Mesh"
meshtastic --ch-set psk base64:your-key-here
```

### Reticulum Interface Configuration
Edit `~/.reticulum/config`:
```ini
[interfaces]
  [[RNode LoRa Interface]]
    type = RNodeInterface
    enabled = yes
    port = /dev/ttyUSB0
    frequency = 915000000
    bandwidth = 125000
    txpower = 7
    spreadingfactor = 8
    codingrate = 5
```

### SDR Configuration
GQRX config (`~/.config/gqrx/default.conf`):
```ini
[General]
crashed=false

[receiver]
frequency=100000000
sample_rate=2400000
```

## Performance Optimization

### For LoRa
- Increase USB buffer sizes
- Real-time kernel (optional)
- CPU governor to performance
- Disable power management on USB

### For SDR
- USB 3.0 highly recommended
- Adequate cooling for continuous operation
- Isolate USB controllers
- Reduce sample rate if CPU limited

### For Mesh Networking
- Optimize routing protocols
- Configure appropriate intervals
- Monitor link quality
- Use appropriate TX power

## Troubleshooting

### Meshtastic Device Not Detected
```bash
# Check USB
lsusb | grep -i "Silicon Labs\|CP210\|CH340"

# Check permissions
ls -l /dev/ttyUSB*

# Add user to dialout group
sudo usermod -a -G dialout $USER
```

### SDR Not Working
```bash
# Check if device detected
rtl_test -t
hackrf_info
LimeUtil --find

# Install udev rules
sudo cp /usr/local/share/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

### LoRa Gateway Issues
```bash
# Check SPI enabled (Raspberry Pi)
lsmod | grep spi

# Test concentrator
cd /opt/lora/sx1302_hal
./test_loragw_hal
```

## Advanced Features

### Remote SDR Server
```bash
# Install OpenWebRX
# Access from any browser on network
# Multiple users simultaneously
```

### Mesh Network Bridging
```bash
# Bridge Meshtastic to Reticulum
# Forward messages between protocols
# Use MQTT integration
```

### LoRa to IP Gateway
```bash
# ChirpStack provides IP connectivity
# Connect LoRa devices to internet
# Cloud integration support
```

## Resource Usage

| Software | RAM Usage | CPU Usage | Notes |
|----------|-----------|-----------|-------|
| Edge Browser | 100-300MB | 2-10% | Per tab |
| Meshtastic CLI | <50MB | <1% | Minimal |
| NomadNet | 30-50MB | <1% | Efficient |
| GQRX | 100-200MB | 10-30% | Depends on sample rate |
| GNU Radio | 200-500MB | 20-60% | Complex flowgraphs |
| ChirpStack | 100-200MB | 2-5% | Gateway mode |

## Updates

```bash
# Update all mesh/radio software
sudo icenet-mesh-radio-update

# Or update individual components
sudo apt update && sudo apt upgrade
pip3 install --upgrade meshtastic reticulum nomadnet
```

## Documentation Links

- Meshtastic: https://meshtastic.org
- Reticulum: https://reticulum.network
- NomadNet: https://github.com/markqvist/NomadNet
- ChirpStack: https://www.chirpstack.io
- GNU Radio: https://www.gnuradio.org
- GQRX: https://gqrx.dk

## Community

Join IceNet-OS mesh networking community for support, examples, and collaboration.

## License

Individual software packages retain their original licenses. See respective projects for details.
