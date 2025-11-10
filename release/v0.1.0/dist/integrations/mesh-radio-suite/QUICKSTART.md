# IceNet-OS Mesh & Radio Suite - Quick Start Guide

Get up and running with mesh networking, LoRa, and SDR in minutes!

## Installation

```bash
cd /home/user/IceNet-OS/integrations
sudo ./install-integrations.sh --mesh-radio-suite
```

Or install specific components:
```bash
cd mesh-radio-suite
sudo ./install-mesh-radio-suite.sh --meshtastic  # Just Meshtastic
sudo ./install-mesh-radio-suite.sh --reticulum   # Just Reticulum
sudo ./install-mesh-radio-suite.sh --sdr         # Just SDR tools
```

## 5-Minute Quick Starts

### 1. Meshtastic Node Setup (5 minutes)

**What you need:**
- Meshtastic-compatible device (ESP32 with LoRa)
- USB cable

**Steps:**
```bash
# 1. Connect device via USB
# 2. Check connection
lsusb | grep -i "Silicon Labs\|CP210"

# 3. Get device info
meshtastic --info

# 4. Set your region (REQUIRED)
meshtastic --set lora.region US

# 5. Set your name
meshtastic --set-owner "YourName"

# 6. Send a message
meshtastic --sendtext "Hello from IceNet-OS!"

# 7. Monitor messages
meshtastic --listen
```

**GUI Option:**
- Open Start Menu → Mesh Networking → Meshtastic Web Interface
- Configure visually in browser

**Result:** Your Meshtastic node is now part of the mesh network!

### 2. Reticulum Mesh Network (10 minutes)

**What you need:**
- RNode device OR internet connection

**Steps:**
```bash
# 1. Start NomadNet (terminal-based mesh client)
nomadnet

# 2. Navigate with arrow keys:
#    - N: Network
#    - C: Conversations
#    - F: Files
#    - B: Boards

# 3. Send a message:
#    - Press 'C' for conversations
#    - Press 'n' for new conversation
#    - Enter destination address
#    - Type message, press Ctrl+D to send

# 4. Browse mesh network:
#    - Press 'N' for network
#    - See all reachable nodes
#    - View node info and stats
```

**With RNode Hardware:**
```bash
# Configure RNode
rnodeconf /dev/ttyUSB0

# Edit Reticulum config
nano ~/.reticulum/config
# Enable RNode interface section

# Restart NomadNet
nomadnet
```

**Result:** You're connected to the Reticulum mesh network!

### 3. SDR Reception (2 minutes)

**What you need:**
- RTL-SDR dongle (or any supported SDR)
- Antenna

**Steps:**
```bash
# 1. Test SDR connection
rtl_test -t

# 2. Launch GQRX (GUI SDR receiver)
gqrx

# 3. In GQRX:
#    - Click "Configure I/O devices"
#    - Select your SDR
#    - Click OK
#    - Click play button (top left)
#    - Tune to a frequency (e.g., 100.0 MHz for FM radio)
#    - Adjust gain slider
```

**Presets to try:**
- 88-108 MHz: FM radio
- 118-137 MHz: Aircraft
- 144-148 MHz: Ham 2m band
- 462 MHz: FRS/GMRS
- 1090 MHz: ADS-B aircraft transponders

**Result:** You're receiving radio signals!

### 4. Aircraft Tracking (3 minutes)

**What you need:**
- RTL-SDR dongle
- Antenna (dipole at ~13cm works great)

**Steps:**
```bash
# 1. Start dump1090
dump1090 --interactive --net

# 2. Open browser to http://localhost:8080

# 3. See live aircraft on map!
```

**Alternative GUI launch:**
- Start Menu → SDR Tools → Decoders → dump1090 (Aircraft)

**Result:** Real-time flight tracking on your screen!

### 5. LoRaWAN Gateway (15 minutes)

**What you need:**
- Raspberry Pi with LoRa concentrator HAT (SX1302/SX1301)
- Gateway registration on ChirpStack or TTN

**Steps:**
```bash
# 1. Enable SPI
sudo raspi-config
# Interface Options → SPI → Enable

# 2. Test concentrator
cd /opt/lora/sx1302_hal
./test_loragw_hal

# 3. Configure ChirpStack
sudo nano /etc/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml
# Set gateway ID and server details

# 4. Start services
sudo systemctl start chirpstack-gateway-bridge
sudo systemctl enable chirpstack-gateway-bridge

# 5. Check status
sudo systemctl status chirpstack-gateway-bridge

# 6. Open web interface
# http://localhost:8080
```

**Result:** Your LoRaWAN gateway is live!

### 6. Ham Radio Digital Modes (5 minutes)

**What you need:**
- RTL-SDR or other SDR
- Virtual audio cable setup

**Steps:**
```bash
# 1. Start GQRX tuned to HF digital freq
gqrx
# Tune to 14.074 MHz (FT8)

# 2. Start WSJT-X
wsjtx

# 3. Configure:
#    - Set radio to "None"
#    - Enable "Monitor"
#    - Watch decodes appear!
```

**Result:** Decoding FT8/FT4 signals from around the world!

## Common Tasks

### Send Meshtastic Message to Specific Node
```bash
# Get node list
meshtastic --nodes

# Send to specific node
meshtastic --dest '!abc12345' --sendtext "Private message"
```

### Share Files via Reticulum
```bash
# In NomadNet:
# 1. Press 'F' for Files
# 2. Press 'u' to upload
# 3. Select file
# 4. Share link with recipient
```

### Record SDR Signal
```bash
# In GQRX, click red recording button
# Or via command line:
rtl_sdr -f 100.0M -s 2.4M -g 40 recording.raw
```

### Scan for LoRa Devices
```bash
meshtastic --nodes  # Meshtastic nodes
rnsd --list         # Reticulum nodes over network
```

### Analyze Unknown Signal
```bash
# 1. Record signal with GQRX or rtl_sdr
# 2. Open in Inspectrum:
inspectrum recording.raw

# 3. Or use Universal Radio Hacker:
urh
# File → Open → Select recording
# Analyze signal structure
```

## Troubleshooting

### "Permission denied" accessing USB device
```bash
# Add your user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in
```

### RTL-SDR not detected
```bash
# Check if device is seen
lsusb | grep Real

# Install udev rules
sudo cp /usr/local/share/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

# Replug device
```

### Meshtastic can't find device
```bash
# List serial ports
ls -l /dev/ttyUSB* /dev/ttyACM*

# Specify port explicitly
meshtastic --port /dev/ttyUSB0 --info
```

### GQRX "No device found"
```bash
# Check if rtl-sdr works
rtl_test -t

# If DVB-T drivers loaded, blacklist them
echo "blacklist dvb_usb_rtl28xxu" | sudo tee /etc/modprobe.d/blacklist-rtl.conf
sudo rmmod dvb_usb_rtl28xxu
```

### ChirpStack not receiving packets
```bash
# Check concentrator
cd /opt/lora/sx1302_hal
./test_loragw_hal

# Check gateway logs
journalctl -fu chirpstack-gateway-bridge

# Verify SPI enabled
lsmod | grep spi
```

## Next Steps

### Meshtastic
- Configure channels and encryption
- Set up position reporting
- Enable modules (store-forward, range test)
- Build mesh network with friends
- Set up solar-powered remote nodes

### Reticulum
- Set up RNode hardware
- Run LXMF propagation node
- Create bulletin boards in NomadNet
- Share files over the mesh
- Bridge to internet

### LoRa
- Deploy multi-gateway network
- Connect sensors and devices
- Set up network server
- Monitor coverage
- Join The Things Network

### SDR
- Build GNU Radio flowgraphs
- Decode weather satellites (NOAA, Meteor)
- Receive ISS SSTV images
- Track satellites with Gpredict
- Experiment with transmission (with license!)

## Resources

**Meshtastic:**
- Official docs: https://meshtastic.org
- Devices: https://meshtastic.org/docs/hardware
- Channel calculator: https://meshtastic.org/docs/settings/channels

**Reticulum:**
- Documentation: https://reticulum.network
- Forum: https://github.com/markqvist/Reticulum/discussions
- Hardware: https://unsigned.io/rnode/

**LoRa:**
- ChirpStack docs: https://www.chirpstack.io
- The Things Network: https://www.thethingsnetwork.org
- LoRaWAN spec: https://lora-alliance.org

**SDR:**
- RTL-SDR blog: https://www.rtl-sdr.com
- GNU Radio tutorials: https://wiki.gnuradio.org
- Signal ID wiki: https://www.sigidwiki.com

**Ham Radio:**
- WSJT-X guide: https://physics.princeton.edu/pulsar/k1jt/wsjtx.html
- fldigi wiki: http://www.w1hkj.com/FldigiHelp/index.html
- APRS: http://www.aprs.org

## Community

Join the IceNet-OS mesh networking community:
- Share configurations
- Get help
- Show off your setups
- Coordinate mesh networks
- Contribute improvements

Happy meshing and experimenting! 📡🌐
