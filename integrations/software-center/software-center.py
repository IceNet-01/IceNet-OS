#!/usr/bin/env python3
"""
IceNet Software Center
Graphical package selector for optional components
"""

import sys
import subprocess
import json
import os
from pathlib import Path

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Pango

class SoftwareCenter(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="IceNet Software Center")
        self.set_default_size(900, 600)
        self.set_position(Gtk.WindowPosition.CENTER)

        # Package definitions
        self.packages = self.load_packages()
        self.selected_packages = set()

        self.build_ui()

    def load_packages(self):
        """Load available package definitions"""
        return [
            {
                "id": "mesh-radio-suite",
                "name": "Mesh & Radio Suite",
                "description": "Complete mesh networking and SDR suite",
                "details": "Includes: Edge browser, Meshtastic, Reticulum (NomadNet), LoRa tools, SDR tools (GNU Radio, GQRX, dump1090, rtl_433), Mesh protocols (Yggdrasil, cjdns, Babel, BATMAN-adv)",
                "size": "~2.5 GB",
                "category": "Networking",
                "script": "/opt/icenet/integrations/mesh-radio-suite/install-mesh-radio-suite.sh"
            },
            {
                "id": "thermal-management",
                "name": "Thermal Management System",
                "description": "CPU-based heating for cold environments",
                "details": "Automatically heats hardware in sub-zero temperatures by running CPU-intensive tasks. Perfect for outdoor installations.",
                "size": "~5 MB",
                "category": "System",
                "script": "/opt/icenet/integrations/install-integrations.sh --thermal"
            },
            {
                "id": "meshtastic-bridge",
                "name": "Meshtastic Bridge (Headless)",
                "description": "Production mesh radio bridge service",
                "details": "Headless bridge for Meshtastic radios with automatic recovery and monitoring",
                "size": "~50 MB",
                "category": "Networking",
                "script": "/opt/icenet/integrations/install-integrations.sh --bridge"
            },
            {
                "id": "mesh-bridge-gui",
                "name": "Mesh Bridge GUI",
                "description": "Visual mesh bridge configuration",
                "details": "Desktop GUI for managing and monitoring Meshtastic bridge service",
                "size": "~10 MB",
                "category": "Networking",
                "script": "/opt/icenet/integrations/install-integrations.sh --mesh-gui"
            },
            {
                "id": "development-tools",
                "name": "Development Tools",
                "description": "Programming and development suite",
                "details": "Includes: Python3, Node.js, Git, VSCodium, build-essential, debugging tools",
                "size": "~800 MB",
                "category": "Development",
                "script": "/opt/icenet/integrations/dev-tools/install-dev-tools.sh"
            }
        ]

    def build_ui(self):
        """Build the main UI"""
        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(main_box)

        # Header
        header_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        header_box.set_margin_start(20)
        header_box.set_margin_end(20)
        header_box.set_margin_top(20)
        header_box.set_margin_bottom(10)
        main_box.pack_start(header_box, False, False, 0)

        title = Gtk.Label()
        title.set_markup("<span size='xx-large' weight='bold'>IceNet Software Center</span>")
        header_box.pack_start(title, False, False, 0)

        subtitle = Gtk.Label()
        subtitle.set_markup("<span size='large'>Select optional components to install</span>")
        header_box.pack_start(subtitle, False, False, 0)

        # Content area with scrolling
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scrolled, True, True, 0)

        # Package list
        list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        list_box.set_margin_start(20)
        list_box.set_margin_end(20)
        list_box.set_margin_top(10)
        list_box.set_margin_bottom(10)
        scrolled.add(list_box)

        # Add package cards
        for pkg in self.packages:
            card = self.create_package_card(pkg)
            list_box.pack_start(card, False, False, 0)

        # Bottom toolbar
        toolbar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        toolbar.set_margin_start(20)
        toolbar.set_margin_end(20)
        toolbar.set_margin_top(10)
        toolbar.set_margin_bottom(20)
        main_box.pack_start(toolbar, False, False, 0)

        self.status_label = Gtk.Label()
        self.status_label.set_markup("<i>Select packages and click Install</i>")
        self.status_label.set_xalign(0)
        toolbar.pack_start(self.status_label, True, True, 0)

        # Install button
        install_btn = Gtk.Button(label="Install Selected")
        install_btn.get_style_context().add_class('suggested-action')
        install_btn.connect("clicked", self.on_install_clicked)
        toolbar.pack_start(install_btn, False, False, 0)

        # Close button
        close_btn = Gtk.Button(label="Close")
        close_btn.connect("clicked", lambda x: self.destroy())
        toolbar.pack_start(close_btn, False, False, 0)

    def create_package_card(self, pkg):
        """Create a package selection card"""
        frame = Gtk.Frame()
        frame.set_shadow_type(Gtk.ShadowType.IN)

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        box.set_margin_start(15)
        box.set_margin_end(15)
        box.set_margin_top(15)
        box.set_margin_bottom(15)
        frame.add(box)

        # Checkbox
        check = Gtk.CheckButton()
        check.connect("toggled", self.on_package_toggled, pkg["id"])
        box.pack_start(check, False, False, 0)

        # Package info
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        box.pack_start(info_box, True, True, 0)

        # Name and category
        name_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        info_box.pack_start(name_box, False, False, 0)

        name_label = Gtk.Label()
        name_label.set_markup(f"<b>{pkg['name']}</b>")
        name_label.set_xalign(0)
        name_box.pack_start(name_label, False, False, 0)

        category_label = Gtk.Label()
        category_label.set_markup(f"<small><i>{pkg['category']}</i></small>")
        name_box.pack_start(category_label, False, False, 0)

        # Description
        desc_label = Gtk.Label()
        desc_label.set_text(pkg["description"])
        desc_label.set_xalign(0)
        desc_label.set_line_wrap(True)
        info_box.pack_start(desc_label, False, False, 0)

        # Details (expandable)
        details_expander = Gtk.Expander()
        details_expander.set_label("Details")
        info_box.pack_start(details_expander, False, False, 0)

        details_label = Gtk.Label()
        details_label.set_text(pkg["details"])
        details_label.set_xalign(0)
        details_label.set_line_wrap(True)
        details_label.set_margin_start(10)
        details_expander.add(details_label)

        # Size
        size_label = Gtk.Label()
        size_label.set_markup(f"<b>Size:</b> {pkg['size']}")
        size_label.set_xalign(0)
        box.pack_start(size_label, False, False, 0)

        return frame

    def on_package_toggled(self, button, pkg_id):
        """Handle package selection toggle"""
        if button.get_active():
            self.selected_packages.add(pkg_id)
        else:
            self.selected_packages.discard(pkg_id)

        if self.selected_packages:
            count = len(self.selected_packages)
            self.status_label.set_markup(f"<b>{count}</b> package(s) selected")
        else:
            self.status_label.set_markup("<i>Select packages and click Install</i>")

    def on_install_clicked(self, button):
        """Handle install button click"""
        if not self.selected_packages:
            self.show_message("No Selection", "Please select at least one package to install")
            return

        # Confirm installation
        selected_names = [p["name"] for p in self.packages if p["id"] in self.selected_packages]
        dialog = Gtk.MessageDialog(
            parent=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Confirm Installation"
        )
        dialog.format_secondary_text(
            f"Install the following packages?\n\n" + "\n".join(f"• {name}" for name in selected_names) +
            "\n\nThis may take several minutes and require internet connection."
        )
        response = dialog.run()
        dialog.destroy()

        if response == Gtk.ResponseType.YES:
            self.install_packages()

    def install_packages(self):
        """Install selected packages"""
        self.status_label.set_markup("<b>Installing packages...</b> This may take a while")

        # Get scripts to run
        scripts_to_run = [p["script"] for p in self.packages if p["id"] in self.selected_packages]

        # Show progress dialog
        dialog = Gtk.MessageDialog(
            parent=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.NONE,
            text="Installing Packages"
        )
        dialog.format_secondary_text("Please wait while packages are being installed...")
        dialog.show_all()

        # Run installations in terminal
        for script in scripts_to_run:
            if os.path.exists(script):
                # Open terminal to run script
                subprocess.Popen(['lxterminal', '-e', f'bash -c "sudo {script}; echo; echo Installation complete. Press Enter to continue...; read"'])

        dialog.destroy()
        self.status_label.set_markup("<b>Installation started</b> - Check terminal windows")
        self.show_message("Installation Started", "Package installation is running in terminal windows.\nPlease follow the prompts in each terminal.")

    def show_message(self, title, message):
        """Show a simple message dialog"""
        dialog = Gtk.MessageDialog(
            parent=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()

def main():
    """Main entry point"""
    try:
        win = SoftwareCenter()
        win.connect("destroy", Gtk.main_quit)
        win.show_all()
        Gtk.main()
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
