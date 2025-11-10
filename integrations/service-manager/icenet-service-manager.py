#!/usr/bin/env python3
"""
IceNet-OS Service Control Panel
Graphical interface for managing IceNet services and integrations
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
import subprocess
import os

class ServiceControlPanel(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="IceNet Service Manager")
        self.set_default_size(600, 500)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(10)

        # Services configuration
        self.services = [
            {
                'name': 'Thermal Management',
                'service': 'icenet-thermal',
                'description': 'CPU-based heating for cold environments',
                'icon': '🌡️',
                'enabled': False
            },
            {
                'name': 'Meshtastic Bridge (Headless)',
                'service': 'meshtastic-bridge',
                'description': 'Headless bridge service for Meshtastic radios',
                'icon': '📡',
                'enabled': False
            },
            {
                'name': 'Mesh Bridge GUI',
                'service': 'mesh-bridge-gui',
                'description': 'Visual interface for mesh bridge configuration',
                'icon': '🖥️',
                'enabled': False
            }
        ]

        # Create UI
        self.create_ui()

        # Load current service states
        self.refresh_service_states()

    def create_ui(self):
        """Create the main UI"""
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(main_box)

        # Header
        header = Gtk.Label()
        header.set_markup("<span size='x-large' weight='bold'>IceNet Service Manager</span>")
        header.set_halign(Gtk.Align.START)
        main_box.pack_start(header, False, False, 0)

        description = Gtk.Label()
        description.set_markup(
            "<span>Manage which IceNet services run automatically at system boot.</span>"
        )
        description.set_halign(Gtk.Align.START)
        main_box.pack_start(description, False, False, 0)

        # Separator
        separator = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        main_box.pack_start(separator, False, False, 5)

        # Services list
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scrolled, True, True, 0)

        services_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        services_box.set_margin_start(10)
        services_box.set_margin_end(10)
        scrolled.add(services_box)

        # Create service cards
        for service in self.services:
            card = self.create_service_card(service)
            services_box.pack_start(card, False, False, 0)

        # Bottom buttons
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        button_box.set_halign(Gtk.Align.END)
        main_box.pack_start(button_box, False, False, 0)

        refresh_btn = Gtk.Button(label="↻ Refresh")
        refresh_btn.connect("clicked", lambda x: self.refresh_service_states())
        button_box.pack_start(refresh_btn, False, False, 0)

        close_btn = Gtk.Button(label="Close")
        close_btn.connect("clicked", lambda x: Gtk.main_quit())
        button_box.pack_start(close_btn, False, False, 0)

    def create_service_card(self, service):
        """Create a card for each service"""
        # Frame
        frame = Gtk.Frame()
        frame.set_shadow_type(Gtk.ShadowType.ETCHED_IN)

        # Main box
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        box.set_margin_start(15)
        box.set_margin_end(15)
        box.set_margin_top(15)
        box.set_margin_bottom(15)
        frame.add(box)

        # Icon
        icon_label = Gtk.Label()
        icon_label.set_markup(f"<span size='xx-large'>{service['icon']}</span>")
        box.pack_start(icon_label, False, False, 0)

        # Info box
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.pack_start(info_box, True, True, 0)

        # Service name
        name_label = Gtk.Label()
        name_label.set_markup(f"<span weight='bold' size='large'>{service['name']}</span>")
        name_label.set_halign(Gtk.Align.START)
        info_box.pack_start(name_label, False, False, 0)

        # Description
        desc_label = Gtk.Label(label=service['description'])
        desc_label.set_halign(Gtk.Align.START)
        desc_label.set_line_wrap(True)
        info_box.pack_start(desc_label, False, False, 0)

        # Status label
        status_label = Gtk.Label()
        service['status_label'] = status_label
        status_label.set_halign(Gtk.Align.START)
        info_box.pack_start(status_label, False, False, 0)

        # Control box
        control_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.pack_start(control_box, False, False, 0)

        # Enable/Disable switch
        switch = Gtk.Switch()
        switch.set_valign(Gtk.Align.CENTER)
        service['switch'] = switch
        switch.connect("notify::active", self.on_switch_activated, service)
        control_box.pack_start(switch, False, False, 0)

        # Action buttons
        action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        control_box.pack_start(action_box, False, False, 0)

        start_btn = Gtk.Button(label="▶ Start")
        start_btn.connect("clicked", self.on_start_service, service)
        action_box.pack_start(start_btn, False, False, 0)

        stop_btn = Gtk.Button(label="⬛ Stop")
        stop_btn.connect("clicked", self.on_stop_service, service)
        action_box.pack_start(stop_btn, False, False, 0)

        return frame

    def run_command(self, command):
        """Run a system command"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True
            )
            return result.returncode == 0, result.stdout, result.stderr
        except Exception as e:
            return False, "", str(e)

    def is_service_enabled(self, service_name):
        """Check if service is enabled"""
        success, stdout, _ = self.run_command(f"systemctl is-enabled {service_name} 2>/dev/null")
        return "enabled" in stdout

    def is_service_active(self, service_name):
        """Check if service is currently running"""
        success, stdout, _ = self.run_command(f"systemctl is-active {service_name} 2>/dev/null")
        return "active" in stdout

    def refresh_service_states(self):
        """Refresh the state of all services"""
        for service in self.services:
            service_name = service['service']

            enabled = self.is_service_enabled(service_name)
            active = self.is_service_active(service_name)

            service['enabled'] = enabled
            service['active'] = active

            # Update switch without triggering signal
            service['switch'].handler_block_by_func(self.on_switch_activated)
            service['switch'].set_active(enabled)
            service['switch'].handler_unblock_by_func(self.on_switch_activated)

            # Update status label
            if active:
                status_text = "<span foreground='green'>● Running</span>"
            else:
                status_text = "<span foreground='grey'>○ Stopped</span>"

            if enabled:
                status_text += " | <span>Enabled at boot</span>"
            else:
                status_text += " | <span>Disabled at boot</span>"

            service['status_label'].set_markup(status_text)

    def on_switch_activated(self, switch, gparam, service):
        """Handle switch toggle"""
        if switch.get_active():
            self.enable_service(service)
        else:
            self.disable_service(service)

    def enable_service(self, service):
        """Enable service at boot"""
        service_name = service['service']
        success, _, error = self.run_command(f"pkexec systemctl enable {service_name}")

        if success:
            self.show_notification(f"{service['name']} enabled", "Service will start at boot")
            self.refresh_service_states()
        else:
            self.show_error(f"Failed to enable {service['name']}", error)
            service['switch'].set_active(False)

    def disable_service(self, service):
        """Disable service at boot"""
        service_name = service['service']
        success, _, error = self.run_command(f"pkexec systemctl disable {service_name}")

        if success:
            self.show_notification(f"{service['name']} disabled", "Service will not start at boot")
            self.refresh_service_states()
        else:
            self.show_error(f"Failed to disable {service['name']}", error)
            service['switch'].set_active(True)

    def on_start_service(self, button, service):
        """Start service now"""
        service_name = service['service']
        success, _, error = self.run_command(f"pkexec systemctl start {service_name}")

        if success:
            self.show_notification(f"{service['name']} started", "Service is now running")
            GLib.timeout_add_seconds(1, self.refresh_service_states)
        else:
            self.show_error(f"Failed to start {service['name']}", error)

    def on_stop_service(self, button, service):
        """Stop service now"""
        service_name = service['service']
        success, _, error = self.run_command(f"pkexec systemctl stop {service_name}")

        if success:
            self.show_notification(f"{service['name']} stopped", "Service has been stopped")
            GLib.timeout_add_seconds(1, self.refresh_service_states)
        else:
            self.show_error(f"Failed to stop {service['name']}", error)

    def show_notification(self, title, message):
        """Show notification dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

    def show_error(self, title, message):
        """Show error dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

def main():
    win = ServiceControlPanel()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()
