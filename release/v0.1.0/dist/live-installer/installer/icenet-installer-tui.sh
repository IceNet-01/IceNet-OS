#!/bin/bash
# IceNet-OS Text-based Installer
# Curses/Dialog-based installer for headless installations

set -e

# Source backend
source /usr/local/lib/icenet-installer-backend.sh

# Dialog settings
DIALOG=${DIALOG=dialog}
TITLE="IceNet-OS Installer"

# Temp file for dialog output
TEMPFILE=$(mktemp)
trap "rm -f $TEMPFILE" EXIT

# Check prerequisites
check_prerequisites() {
    if [ $(id -u) -ne 0 ]; then
        echo "Error: Installer must be run as root"
        exit 1
    fi

    if [ ! -f /run/icenet/live-boot ]; then
        echo "Error: Installer must be run from live boot"
        exit 1
    fi

    if ! command -v dialog &>/dev/null; then
        echo "Error: dialog not found. Installing..."
        apt-get update && apt-get install -y dialog
    fi
}

# Welcome screen
show_welcome() {
    $DIALOG --title "$TITLE" --yesno \
        "Welcome to IceNet-OS Installer\n\n\
This wizard will guide you through installing IceNet-OS to your hard drive.\n\n\
Features:\n\
• Lightweight and fast\n\
• Secure by default\n\
• Mesh networking ready\n\
• SDR and LoRa support\n\
• Perfect for edge computing\n\n\
Do you want to continue?" 20 70

    if [ $? -ne 0 ]; then
        clear
        exit 0
    fi
}

# Select disk
select_disk() {
    local disks=()
    local i=0

    # Get disk list
    while IFS=: read -r disk size; do
        model=$(lsblk -ndo MODEL "$disk" 2>/dev/null || echo "Unknown")
        disks+=("$disk" "$size - $model")
        ((i++))
    done < <(detect_disks)

    if [ $i -eq 0 ]; then
        $DIALOG --title "$TITLE" --msgbox "No suitable disks found!" 10 40
        return 1
    fi

    $DIALOG --title "$TITLE" --menu \
        "⚠ WARNING: All data on selected disk will be ERASED!\n\nSelect installation disk:" \
        20 70 10 "${disks[@]}" 2>$TEMPFILE

    if [ $? -ne 0 ]; then
        return 1
    fi

    INSTALL_DISK=$(cat $TEMPFILE)

    # Confirmation
    $DIALOG --title "$TITLE" --defaultno --yesno \
        "⚠ FINAL WARNING ⚠\n\n\
This will PERMANENTLY ERASE all data on:\n\
$INSTALL_DISK\n\n\
Are you absolutely sure?" 15 60

    return $?
}

# Configure hostname
configure_hostname() {
    $DIALOG --title "$TITLE" --inputbox \
        "Enter hostname for your system:" 10 60 "icenet" 2>$TEMPFILE

    if [ $? -ne 0 ]; then
        return 1
    fi

    HOSTNAME=$(cat $TEMPFILE)

    if [ -z "$HOSTNAME" ]; then
        $DIALOG --title "$TITLE" --msgbox "Hostname cannot be empty!" 8 40
        return 1
    fi

    return 0
}

# Configure user
configure_user() {
    # Username
    $DIALOG --title "$TITLE" --inputbox \
        "Enter username:" 10 60 "icenet" 2>$TEMPFILE

    if [ $? -ne 0 ]; then
        return 1
    fi

    USERNAME=$(cat $TEMPFILE)

    if [ -z "$USERNAME" ]; then
        $DIALOG --title "$TITLE" --msgbox "Username cannot be empty!" 8 40
        return 1
    fi

    # Password
    while true; do
        $DIALOG --title "$TITLE" --insecure --passwordbox \
            "Enter password for $USERNAME:" 10 60 2>$TEMPFILE

        if [ $? -ne 0 ]; then
            return 1
        fi

        PASSWORD=$(cat $TEMPFILE)

        if [ ${#PASSWORD} -lt 4 ]; then
            $DIALOG --title "$TITLE" --msgbox \
                "Password must be at least 4 characters!" 8 50
            continue
        fi

        # Confirm password
        $DIALOG --title "$TITLE" --insecure --passwordbox \
            "Confirm password:" 10 60 2>$TEMPFILE

        CONFIRM=$(cat $TEMPFILE)

        if [ "$PASSWORD" = "$CONFIRM" ]; then
            break
        else
            $DIALOG --title "$TITLE" --msgbox "Passwords do not match!" 8 40
        fi
    done

    return 0
}

# Configure timezone
configure_timezone() {
    # Common timezones
    local zones=(
        "America/New_York" "US Eastern"
        "America/Chicago" "US Central"
        "America/Denver" "US Mountain"
        "America/Los_Angeles" "US Pacific"
        "Europe/London" "UK"
        "Europe/Paris" "Central Europe"
        "Asia/Tokyo" "Japan"
        "Asia/Shanghai" "China"
        "Australia/Sydney" "Australia"
        "UTC" "UTC"
    )

    $DIALOG --title "$TITLE" --menu \
        "Select timezone:" 20 60 10 "${zones[@]}" 2>$TEMPFILE

    if [ $? -ne 0 ]; then
        return 1
    fi

    TIMEZONE=$(cat $TEMPFILE)
    return 0
}

# Show summary
show_summary() {
    $DIALOG --title "$TITLE" --yesno \
        "Ready to Install\n\n\
Installation Summary:\n\
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\
Disk:     $INSTALL_DISK\n\
Hostname: $HOSTNAME\n\
Username: $USERNAME\n\
Timezone: $TIMEZONE\n\
Locale:   en_US.UTF-8\n\
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n\
⚠ Last chance to cancel!\n\
Proceed with installation?" 20 70

    return $?
}

# Run installation with progress
run_installation() {
    # Create pipe for progress
    PROGRESS_PIPE=$(mktemp -u)
    mkfifo $PROGRESS_PIPE
    trap "rm -f $PROGRESS_PIPE" EXIT

    # Start progress dialog
    $DIALOG --title "$TITLE" --gauge "Preparing installation..." 10 70 0 <$PROGRESS_PIPE &
    DIALOG_PID=$!

    # Run installation and parse progress
    (
        full_install "$INSTALL_DISK" "$HOSTNAME" "$USERNAME" "$PASSWORD" "$TIMEZONE" "en_US.UTF-8" 2>&1 | \
        while IFS= read -r line; do
            if [[ "$line" =~ PROGRESS:([0-9]+):(.*) ]]; then
                echo "${BASH_REMATCH[1]}"
                echo "XXX"
                echo "${BASH_REMATCH[2]}"
                echo "XXX"
            fi
        done
        echo "100"
    ) >$PROGRESS_PIPE

    wait $DIALOG_PID

    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Show completion
show_complete() {
    $DIALOG --title "$TITLE" --yesno \
        "✓ Installation Complete!\n\n\
IceNet-OS has been successfully installed to:\n\
$INSTALL_DISK\n\n\
You can now reboot and remove the installation media.\n\n\
Reboot now?" 15 60

    if [ $? -eq 0 ]; then
        clear
        echo "Rebooting in 3 seconds..."
        sleep 3
        systemctl reboot
    fi
}

# Show error
show_error() {
    $DIALOG --title "$TITLE" --msgbox \
        "Installation Failed!\n\n\
An error occurred during installation.\n\
Check /tmp/icenet-install.log for details." 12 60
}

# Main installation flow
main() {
    check_prerequisites

    show_welcome || exit 0

    select_disk || exit 1

    configure_hostname || exit 1

    configure_user || exit 1

    configure_timezone || exit 1

    show_summary || exit 1

    if run_installation; then
        show_complete
    else
        show_error
        exit 1
    fi

    clear
}

main
