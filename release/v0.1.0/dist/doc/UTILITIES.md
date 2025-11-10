# IceNet-OS Utilities Guide

IceNet-OS includes a comprehensive set of system utilities for network management, system monitoring, file operations, and text processing.

## Network Utilities

### iceping (ping)

ICMP ping utility for testing network connectivity.

**Usage:**
```bash
iceping <host> [-c count]
ping google.com
ping 192.168.1.1 -c 10
```

**Features:**
- IPv4 support
- Configurable packet count
- Round-trip time measurement
- Packet loss statistics

**Note:** Requires root privileges (raw socket access)

### icenetstat (netstat)

Display network connections, routing tables, and interface statistics.

**Usage:**
```bash
icenetstat          # Show active connections
icenetstat -a       # Show all connections
icenetstat -r       # Show routing table
icenetstat -i       # Show network interfaces
```

**Features:**
- TCP/UDP connection listing
- Routing table display
- Interface statistics
- Connection state information

**Examples:**
```bash
# Show all TCP connections
icenetstat

# Display routing table
icenetstat -r

# Show interface statistics
icenetstat -i
```

### icedownload (wget)

Simple HTTP/HTTPS download utility.

**Usage:**
```bash
icedownload <url> [-O output_file] [-q]
wget https://example.com/file.tar.gz
icedownload https://example.com/data.json -O mydata.json
```

**Features:**
- HTTP/HTTPS support
- Resume capability
- Progress display
- Automatic filename detection

**Options:**
- `-O <file>` - Specify output filename
- `-q, --quiet` - Quiet mode (no progress)

## System Monitoring Tools

### icetop (top)

Real-time process monitor.

**Usage:**
```bash
icetop              # Run continuously
icetop -n 5         # Run 5 iterations
top                 # Alias to icetop
```

**Display:**
- System uptime and load average
- CPU and memory usage
- Process list with:
  - PID (Process ID)
  - User
  - CPU usage percentage
  - Memory usage percentage
  - Virtual memory size
  - Resident set size
  - Process state
  - Command name

**Controls:**
- Ctrl+C to exit

### icefree (free)

Display memory usage information.

**Usage:**
```bash
icefree             # Show in MB
icefree -h          # Human readable (GB)
free                # Alias
```

**Output:**
- Total memory
- Used memory
- Free memory
- Shared memory
- Buffer/cache
- Available memory
- Swap usage (if configured)

**Example:**
```bash
$ icefree -h
              total        used        free      shared  buff/cache   available
Mem:          3.7G        0.5G        2.8G        0.0G        0.4G        3.1G
Swap:         2.0G        0.0G        2.0G
```

### icedf (df)

Display filesystem disk space usage.

**Usage:**
```bash
icedf               # Show in 1K blocks
icedf -h            # Human readable
df -h               # Alias
```

**Output:**
- Filesystem device
- Filesystem type
- Total size
- Used space
- Available space
- Usage percentage
- Mount point

**Example:**
```bash
$ icedf -h
Filesystem           Type       Size   Used  Avail Use% Mounted on
/dev/mmcblk0p2      ext4       29.0G   2.1G  25.5G   8% /
/dev/mmcblk0p1      vfat      256.0M  54.0M 202.0M  21% /boot
```

## File Management Utilities

### icels (ls)

List directory contents.

**Usage:**
```bash
icels [options] [path]
ls -la /etc
```

**Options:**
- `-l` - Long format (detailed listing)
- `-a` - Show all files (including hidden)
- `-h` - Human readable sizes
- `-la` - Long format with all files

**Long Format Display:**
```
drwxr-xr-x  2 root root  4.0K Nov 10 12:34 mydir
-rw-r--r--  1 root root  1.2K Nov 10 12:35 myfile.txt
lrwxrwxrwx  1 root root    10 Nov 10 12:36 mylink -> /path/to/target
```

Shows: permissions, links, owner, group, size, date, name

## Text Processing Utilities

### icecat (cat)

Concatenate and display files.

**Usage:**
```bash
icecat <file> ...
icecat file1.txt file2.txt
cat /etc/hostname
icecat -n file.txt          # Show line numbers
```

**Features:**
- Multiple file support
- Line numbering with `-n`
- Standard input reading
- Pipe support

**Examples:**
```bash
# Display file
cat /etc/hosts

# Concatenate multiple files
cat file1.txt file2.txt > combined.txt

# Display with line numbers
cat -n script.sh

# Read from stdin
echo "Hello World" | cat
```

### icegrep (grep)

Search for patterns in files.

**Usage:**
```bash
icegrep [options] pattern [files...]
grep "error" logfile.txt
icegrep -i "warning" *.log
```

**Options:**
- `-n` - Show line numbers
- `-v` - Invert match (show non-matching lines)
- `-i` - Case insensitive search

**Features:**
- String pattern matching
- Multiple file support
- Line number display
- Case-insensitive search
- Inverted matching

**Examples:**
```bash
# Search for pattern in file
grep "error" /var/log/messages

# Case-insensitive search
grep -i "warning" app.log

# Show line numbers
grep -n "TODO" source.c

# Search multiple files
grep "config" *.conf

# Invert match
grep -v "DEBUG" output.log
```

## Network Management Scripts

### icenet-network

Comprehensive network configuration tool.

**Usage:**
```bash
icenet-network <command> [options]
```

**Commands:**

#### status
Display current network configuration.
```bash
icenet-network status
```

Shows:
- All network interfaces and their states
- IP addresses
- MAC addresses
- Link speeds
- Routing table
- DNS servers

#### list
List available network interfaces.
```bash
icenet-network list
```

#### up / down
Bring interface up or down.
```bash
icenet-network up eth0
icenet-network down eth0
```

#### dhcp
Configure interface for DHCP.
```bash
icenet-network dhcp eth0
```

Automatically:
- Updates `/etc/network/interfaces`
- Brings up interface
- Requests IP address via DHCP

#### static
Configure static IP address.
```bash
icenet-network static eth0 192.168.1.100 255.255.255.0 192.168.1.1
```

Parameters:
1. Interface name
2. IP address
3. Netmask
4. Gateway

#### wifi
Connect to WiFi network.
```bash
icenet-network wifi "MyNetwork" "MyPassword"
icenet-network wifi "OpenNetwork"  # Open network (no password)
```

Automatically:
- Detects WiFi interface
- Configures wpa_supplicant
- Connects to network
- Obtains IP via DHCP

**Examples:**
```bash
# Check network status
icenet-network status

# Configure ethernet with DHCP
icenet-network dhcp eth0

# Set static IP
icenet-network static eth0 10.0.0.50 255.255.255.0 10.0.0.1

# Connect to WiFi
icenet-network wifi "HomeNetwork" "password123"

# Disconnect interface
icenet-network down wlan0
```

### icenet-sysinfo (sysinfo)

Display comprehensive system information.

**Usage:**
```bash
icenet-sysinfo
sysinfo  # Alias
```

**Displays:**
- OS name and version
- Kernel version
- System architecture
- Hostname
- Uptime
- CPU model and core count
- CPU frequency
- Memory usage (total/used/free)
- Storage usage
- Network interfaces and IPs
- Load averages
- Process count
- CPU temperature (if available)

**Example Output:**
```
=====================================
    IceNet-OS System Information
=====================================

Operating System:
  Name: IceNet-OS
  Version: 0.1.0
  Kernel: 6.6.0-icenet
  Architecture: x86_64

Hostname: icenet

Uptime:
  2 days, 5 hours, 34 minutes

CPU:
  Model: Intel(R) Core(TM) i5-8250U
  Cores: 4
  Frequency: 1800 MHz

Memory:
  Total: 8192 MB
  Used: 1024 MB
  Free: 7168 MB

Storage:
  Root: 2.1G / 29.0G used (8%)

Network Interfaces:
  eth0: 192.168.1.100 (up)

Load Average:
  1 min: 0.15
  5 min: 0.22
  15 min: 0.18

Processes:
  Running: 47

Temperature:
  CPU: 45°C

=====================================
```

## Utility Aliases

IceNet-OS creates standard aliases for familiar commands:

| IceNet Utility | Standard Alias |
|----------------|----------------|
| iceping        | ping           |
| icenetstat     | netstat        |
| icedownload    | wget           |
| icetop         | top            |
| icefree        | free           |
| icedf          | df             |
| icels          | ls             |
| icecat         | cat            |
| icegrep        | grep           |
| icenet-sysinfo | sysinfo        |

You can use either name:
```bash
# Both work the same
iceping google.com
ping google.com

# Both work the same
icels -la /etc
ls -la /etc
```

## Tips and Tricks

### Networking

**Quick network diagnostics:**
```bash
# Check connectivity
ping 8.8.8.8

# Check DNS resolution
ping google.com

# View routing
icenetstat -r

# Monitor connections
watch -n 1 icenetstat
```

**Configure network at boot:**

Edit `/etc/network/interfaces`:
```
auto eth0
iface eth0 inet dhcp
```

Or for static:
```
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
```

### System Monitoring

**Watch system resources:**
```bash
# Continuous monitoring
top

# Memory usage
watch -n 1 free -h

# Disk usage
watch -n 1 df -h
```

**Find resource-hungry processes:**
```bash
# Top CPU users (from icetop output)
icetop -n 1

# Check memory
icefree -h
```

### File Operations

**Find large files:**
```bash
du -h /var/log | sort -h | tail -n 10
```

**Search logs:**
```bash
# Find errors
grep -i error /var/log/messages

# Count occurrences
grep -c "failed" /var/log/auth.log

# Search multiple files
grep -n "config" /etc/*.conf
```

**Monitor log files:**
```bash
tail -f /var/log/messages
```

## Integration with Other Tools

### Scripting

All utilities are designed to work well in scripts:

```bash
#!/bin/bash
# Network health check

if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "Network is up"
    icenet-network status
else
    echo "Network is down"
    icenet-network dhcp eth0
fi
```

### Combining Utilities

```bash
# Find processes using memory
icetop -n 1 | grep -v "0.0" | head -n 20

# Network traffic analysis
icenetstat -i | grep -v "0"

# System health report
{
    echo "System Health Report"
    echo "===================="
    icenet-sysinfo
    echo ""
    echo "Disk Usage:"
    icedf -h
    echo ""
    echo "Memory:"
    icefree -h
} > health_report.txt
```

## Performance

All IceNet utilities are optimized for minimal overhead:

- **Binary size**: Each utility < 50KB
- **Memory usage**: < 1MB per utility
- **Startup time**: < 10ms
- **No dependencies**: Statically linked when possible

## Building from Source

To build utilities:

```bash
cd core
make all
sudo make install DESTDIR=/
```

Individual components:
```bash
make -C netutils
make -C sysutils
make -C fileutils
make -C textutils
make -C scripts
```

## Troubleshooting

### iceping: Operation not permitted

Ping requires root privileges. Run as root:
```bash
sudo iceping google.com
```

Or set capabilities:
```bash
sudo setcap cap_net_raw+ep /usr/bin/iceping
```

### icedownload: Failed to initialize curl

Install curl development libraries and rebuild:
```bash
ice-pkg install curl-dev
cd core/netutils
make clean && make
```

### icenet-network: No such command

Ensure scripts are installed:
```bash
cd core/scripts
sudo make install
```

## Future Enhancements

Planned additions:
- SSH client (icessh)
- FTP client (iceftp)
- Text editor (iceedit)
- Archive tools (icetar, icezip)
- Process management (icekill, iceps with more features)
- Disk partitioning (icepartition)

## Contributing

To add new utilities, see [CONTRIBUTING.md](../CONTRIBUTING.md).

Utility requirements:
- Written in C for core utilities
- Bash for complex scripts
- Minimal dependencies
- Clear error messages
- Man page documentation
- Examples in usage text
