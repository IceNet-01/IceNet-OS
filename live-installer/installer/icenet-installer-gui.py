#!/usr/bin/env python3
"""
IceNet-OS Graphical Installer
GTK3-based installer for IceNet-OS
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Pango
import subprocess
import threading
import os
import sys
import re

class InstallerWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="IceNet-OS Installer")
        self.set_default_size(800, 600)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(False)

        # Installation state
        self.install_disk = None
        self.install_config = {
            'hostname': 'icenet',
            'username': 'icenet',
            'password': '',
            'timezone': 'America/New_York',
            'locale': 'en_US.UTF-8'
        }

        # Create notebook for wizard pages
        self.notebook = Gtk.Notebook()
        self.notebook.set_show_tabs(False)
        self.notebook.set_show_border(False)
        self.add(self.notebook)

        # Create pages
        self.create_welcome_page()
        self.create_disk_page()
        self.create_user_page()
        self.create_summary_page()
        self.create_install_page()
        self.create_complete_page()

        # Connect window close event
        self.connect("delete-event", self.on_close)

    def create_welcome_page(self):
        """Welcome screen"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_start(40)
        box.set_margin_end(40)
        box.set_margin_top(40)
        box.set_margin_bottom(40)

        # Title
        title = Gtk.Label()
        title.set_markup("<span size='xx-large' weight='bold'>Welcome to IceNet-OS</span>")
        box.pack_start(title, False, False, 0)

        # Logo area (placeholder)
        logo_box = Gtk.Box()
        logo_box.set_size_request(-1, 150)
        logo_label = Gtk.Label(label="❄️ IceNet-OS")
        logo_label.override_font(Pango.FontDescription("72"))
        logo_box.pack_start(logo_label, True, True, 0)
        box.pack_start(logo_box, False, False, 0)

        # Description
        desc = Gtk.Label()
        desc.set_markup(
            "<span size='large'>This wizard will guide you through installing IceNet-OS\n"
            "to your computer's hard drive.</span>"
        )
        desc.set_line_wrap(True)
        desc.set_justify(Gtk.Justification.CENTER)
        box.pack_start(desc, False, False, 0)

        # Features list
        features = Gtk.Label()
        features.set_markup(
            "\n<b>Features:</b>\n"
            "• Lightweight and fast\n"
            "• Secure by default\n"
            "• Mesh networking ready\n"
            "• SDR and LoRa support\n"
            "• Perfect for edge computing"
        )
        features.set_justify(Gtk.Justification.LEFT)
        box.pack_start(features, False, False, 0)

        # Navigation buttons
        nav_box = Gtk.Box(spacing=10)
        nav_box.set_halign(Gtk.Align.END)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", self.on_cancel)
        nav_box.pack_start(cancel_btn, False, False, 0)

        next_btn = Gtk.Button(label="Next")
        next_btn.get_style_context().add_class("suggested-action")
        next_btn.connect("clicked", lambda x: self.notebook.next_page())
        nav_box.pack_start(next_btn, False, False, 0)

        box.pack_end(nav_box, False, False, 0)

        self.notebook.append_page(box)

    def create_disk_page(self):
        """Disk selection page"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_start(40)
        box.set_margin_end(40)
        box.set_margin_top(40)
        box.set_margin_bottom(40)

        # Title
        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Select Installation Disk</span>")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)

        # Warning
        warning = Gtk.Label()
        warning.set_markup(
            "<span foreground='red' weight='bold'>⚠ WARNING:</span> "
            "All data on the selected disk will be erased!"
        )
        warning.set_halign(Gtk.Align.START)
        box.pack_start(warning, False, False, 0)

        # Disk list
        self.disk_store = Gtk.ListStore(str, str, str)
        self.detect_disks()

        self.disk_view = Gtk.TreeView(model=self.disk_store)
        self.disk_view.set_size_request(-1, 200)

        # Columns
        renderer_text = Gtk.CellRendererText()
        column_disk = Gtk.TreeViewColumn("Disk", renderer_text, text=0)
        column_size = Gtk.TreeViewColumn("Size", renderer_text, text=1)
        column_info = Gtk.TreeViewColumn("Info", renderer_text, text=2)

        self.disk_view.append_column(column_disk)
        self.disk_view.append_column(column_size)
        self.disk_view.append_column(column_info)

        scrolled = Gtk.ScrolledWindow()
        scrolled.add(self.disk_view)
        box.pack_start(scrolled, True, True, 0)

        # Refresh button
        refresh_btn = Gtk.Button(label="↻ Refresh")
        refresh_btn.connect("clicked", lambda x: self.detect_disks())
        refresh_btn.set_halign(Gtk.Align.START)
        box.pack_start(refresh_btn, False, False, 0)

        # Navigation
        nav_box = Gtk.Box(spacing=10)
        nav_box.set_halign(Gtk.Align.END)

        back_btn = Gtk.Button(label="Back")
        back_btn.connect("clicked", lambda x: self.notebook.prev_page())
        nav_box.pack_start(back_btn, False, False, 0)

        next_btn = Gtk.Button(label="Next")
        next_btn.get_style_context().add_class("suggested-action")
        next_btn.connect("clicked", self.on_disk_next)
        nav_box.pack_start(next_btn, False, False, 0)

        box.pack_end(nav_box, False, False, 0)

        self.notebook.append_page(box)

    def create_user_page(self):
        """User configuration page"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_start(40)
        box.set_margin_end(40)
        box.set_margin_top(40)
        box.set_margin_bottom(40)

        # Title
        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>User Configuration</span>")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)

        # Form grid
        grid = Gtk.Grid()
        grid.set_column_spacing(10)
        grid.set_row_spacing(10)
        grid.set_halign(Gtk.Align.CENTER)

        # Hostname
        grid.attach(Gtk.Label(label="Hostname:", halign=Gtk.Align.END), 0, 0, 1, 1)
        self.hostname_entry = Gtk.Entry()
        self.hostname_entry.set_text(self.install_config['hostname'])
        self.hostname_entry.set_width_chars(30)
        grid.attach(self.hostname_entry, 1, 0, 1, 1)

        # Username
        grid.attach(Gtk.Label(label="Username:", halign=Gtk.Align.END), 0, 1, 1, 1)
        self.username_entry = Gtk.Entry()
        self.username_entry.set_text(self.install_config['username'])
        grid.attach(self.username_entry, 1, 1, 1, 1)

        # Password
        grid.attach(Gtk.Label(label="Password:", halign=Gtk.Align.END), 0, 2, 1, 1)
        self.password_entry = Gtk.Entry()
        self.password_entry.set_visibility(False)
        self.password_entry.set_invisible_char('●')
        grid.attach(self.password_entry, 1, 2, 1, 1)

        # Confirm password
        grid.attach(Gtk.Label(label="Confirm:", halign=Gtk.Align.END), 0, 3, 1, 1)
        self.confirm_entry = Gtk.Entry()
        self.confirm_entry.set_visibility(False)
        self.confirm_entry.set_invisible_char('●')
        grid.attach(self.confirm_entry, 1, 3, 1, 1)

        # Timezone
        grid.attach(Gtk.Label(label="Timezone:", halign=Gtk.Align.END), 0, 4, 1, 1)
        self.timezone_entry = Gtk.Entry()
        self.timezone_entry.set_text(self.install_config['timezone'])
        grid.attach(self.timezone_entry, 1, 4, 1, 1)

        box.pack_start(grid, True, False, 0)

        # Error label
        self.user_error_label = Gtk.Label()
        self.user_error_label.set_markup("<span foreground='red'></span>")
        box.pack_start(self.user_error_label, False, False, 0)

        # Navigation
        nav_box = Gtk.Box(spacing=10)
        nav_box.set_halign(Gtk.Align.END)

        back_btn = Gtk.Button(label="Back")
        back_btn.connect("clicked", lambda x: self.notebook.prev_page())
        nav_box.pack_start(back_btn, False, False, 0)

        next_btn = Gtk.Button(label="Next")
        next_btn.get_style_context().add_class("suggested-action")
        next_btn.connect("clicked", self.on_user_next)
        nav_box.pack_start(next_btn, False, False, 0)

        box.pack_end(nav_box, False, False, 0)

        self.notebook.append_page(box)

    def create_summary_page(self):
        """Installation summary page"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_start(40)
        box.set_margin_end(40)
        box.set_margin_top(40)
        box.set_margin_bottom(40)

        # Title
        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Ready to Install</span>")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)

        # Summary
        self.summary_label = Gtk.Label()
        self.summary_label.set_halign(Gtk.Align.START)
        self.summary_label.set_line_wrap(True)
        box.pack_start(self.summary_label, True, False, 0)

        # Warning
        warning = Gtk.Label()
        warning.set_markup(
            "\n<span foreground='red' weight='bold'>⚠ FINAL WARNING</span>\n\n"
            "Clicking 'Install' will permanently erase all data\n"
            "on the selected disk and install IceNet-OS."
        )
        warning.set_justify(Gtk.Justification.CENTER)
        box.pack_start(warning, False, False, 0)

        # Navigation
        nav_box = Gtk.Box(spacing=10)
        nav_box.set_halign(Gtk.Align.END)

        back_btn = Gtk.Button(label="Back")
        back_btn.connect("clicked", lambda x: self.notebook.prev_page())
        nav_box.pack_start(back_btn, False, False, 0)

        install_btn = Gtk.Button(label="Install Now")
        install_btn.get_style_context().add_class("destructive-action")
        install_btn.connect("clicked", self.on_install_clicked)
        nav_box.pack_start(install_btn, False, False, 0)

        box.pack_end(nav_box, False, False, 0)

        self.notebook.append_page(box)

    def create_install_page(self):
        """Installation progress page"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_start(40)
        box.set_margin_end(40)
        box.set_margin_top(40)
        box.set_margin_bottom(40)

        # Title
        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Installing IceNet-OS</span>")
        title.set_halign(Gtk.Align.START)
        box.pack_start(title, False, False, 0)

        # Progress bar
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        box.pack_start(self.progress_bar, False, False, 0)

        # Status label
        self.status_label = Gtk.Label(label="Preparing installation...")
        self.status_label.set_halign(Gtk.Align.START)
        box.pack_start(self.status_label, False, False, 0)

        # Log view
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_size_request(-1, 300)
        self.log_view = Gtk.TextView()
        self.log_view.set_editable(False)
        self.log_view.set_monospace(True)
        self.log_buffer = self.log_view.get_buffer()
        scrolled.add(self.log_view)
        box.pack_start(scrolled, True, True, 0)

        self.notebook.append_page(box)

    def create_complete_page(self):
        """Installation complete page"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_margin_start(40)
        box.set_margin_end(40)
        box.set_margin_top(40)
        box.set_margin_bottom(40)

        # Title
        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>✓ Installation Complete!</span>")
        box.pack_start(title, False, False, 0)

        # Success message
        success_msg = Gtk.Label()
        success_msg.set_markup(
            "\n<span size='large'>IceNet-OS has been successfully installed.</span>\n\n"
            "You can now reboot your computer and remove the\n"
            "installation media to boot into your new system."
        )
        success_msg.set_justify(Gtk.Justification.CENTER)
        success_msg.set_line_wrap(True)
        box.pack_start(success_msg, True, False, 0)

        # Navigation
        nav_box = Gtk.Box(spacing=10)
        nav_box.set_halign(Gtk.Align.END)

        close_btn = Gtk.Button(label="Close")
        close_btn.connect("clicked", lambda x: Gtk.main_quit())
        nav_box.pack_start(close_btn, False, False, 0)

        reboot_btn = Gtk.Button(label="Reboot Now")
        reboot_btn.get_style_context().add_class("suggested-action")
        reboot_btn.connect("clicked", self.on_reboot)
        nav_box.pack_start(reboot_btn, False, False, 0)

        box.pack_end(nav_box, False, False, 0)

        self.notebook.append_page(box)

    def detect_disks(self):
        """Detect available disks"""
        self.disk_store.clear()
        try:
            result = subprocess.run(
                ['bash', '-c', 'source /usr/local/lib/icenet-installer-backend.sh && detect_disks'],
                capture_output=True, text=True
            )
            for line in result.stdout.strip().split('\n'):
                if ':' in line:
                    disk, size = line.split(':', 1)
                    # Get disk model
                    model = subprocess.run(
                        ['lsblk', '-ndo', 'MODEL', disk],
                        capture_output=True, text=True
                    ).stdout.strip()
                    self.disk_store.append([disk, size, model])
        except Exception as e:
            print(f"Error detecting disks: {e}")

    def on_disk_next(self, button):
        """Validate disk selection"""
        selection = self.disk_view.get_selection()
        model, treeiter = selection.get_selected()
        if treeiter:
            self.install_disk = model[treeiter][0]
            self.notebook.next_page()
        else:
            dialog = Gtk.MessageDialog(
                transient_for=self,
                message_type=Gtk.MessageType.ERROR,
                buttons=Gtk.ButtonsType.OK,
                text="Please select a disk"
            )
            dialog.run()
            dialog.destroy()

    def on_user_next(self, button):
        """Validate user configuration"""
        self.install_config['hostname'] = self.hostname_entry.get_text()
        self.install_config['username'] = self.username_entry.get_text()
        password = self.password_entry.get_text()
        confirm = self.confirm_entry.get_text()
        self.install_config['timezone'] = self.timezone_entry.get_text()

        # Validation
        if not self.install_config['hostname']:
            self.user_error_label.set_markup("<span foreground='red'>Hostname cannot be empty</span>")
            return
        if not self.install_config['username']:
            self.user_error_label.set_markup("<span foreground='red'>Username cannot be empty</span>")
            return
        if len(password) < 4:
            self.user_error_label.set_markup("<span foreground='red'>Password must be at least 4 characters</span>")
            return
        if password != confirm:
            self.user_error_label.set_markup("<span foreground='red'>Passwords do not match</span>")
            return

        self.install_config['password'] = password

        # Update summary
        summary_text = (
            f"<b>Installation Disk:</b> {self.install_disk}\n\n"
            f"<b>Hostname:</b> {self.install_config['hostname']}\n"
            f"<b>Username:</b> {self.install_config['username']}\n"
            f"<b>Timezone:</b> {self.install_config['timezone']}\n"
            f"<b>Locale:</b> {self.install_config['locale']}\n"
        )
        self.summary_label.set_markup(summary_text)

        self.notebook.next_page()

    def on_install_clicked(self, button):
        """Start installation"""
        self.notebook.next_page()
        thread = threading.Thread(target=self.run_installation)
        thread.daemon = True
        thread.start()

    def run_installation(self):
        """Run the installation process"""
        try:
            cmd = [
                'bash', '-c',
                f"source /usr/local/lib/icenet-installer-backend.sh && "
                f"full_install '{self.install_disk}' '{self.install_config['hostname']}' "
                f"'{self.install_config['username']}' '{self.install_config['password']}' "
                f"'{self.install_config['timezone']}' '{self.install_config['locale']}'"
            ]

            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )

            for line in process.stdout:
                GLib.idle_add(self.update_install_progress, line)

            process.wait()

            if process.returncode == 0:
                GLib.idle_add(self.installation_complete)
            else:
                GLib.idle_add(self.installation_failed)

        except Exception as e:
            GLib.idle_add(self.installation_failed, str(e))

    def update_install_progress(self, line):
        """Update installation progress"""
        # Parse progress updates
        if line.startswith("PROGRESS:"):
            parts = line.split(':', 2)
            if len(parts) == 3:
                percent = int(parts[1])
                message = parts[2].strip()
                self.progress_bar.set_fraction(percent / 100.0)
                self.status_label.set_text(message)

        # Add to log
        end_iter = self.log_buffer.get_end_iter()
        self.log_buffer.insert(end_iter, line)

        # Auto-scroll
        mark = self.log_buffer.get_insert()
        self.log_view.scroll_to_mark(mark, 0.0, True, 0.0, 1.0)

    def installation_complete(self):
        """Called when installation succeeds"""
        self.notebook.next_page()

    def installation_failed(self, error=None):
        """Called when installation fails"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text="Installation Failed"
        )
        if error:
            dialog.format_secondary_text(f"Error: {error}")
        else:
            dialog.format_secondary_text("Check the installation log for details")
        dialog.run()
        dialog.destroy()

    def on_reboot(self, button):
        """Reboot the system"""
        subprocess.run(['systemctl', 'reboot'])

    def on_cancel(self, button):
        """Cancel installation"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Cancel Installation?"
        )
        dialog.format_secondary_text("Are you sure you want to exit the installer?")
        response = dialog.run()
        dialog.destroy()
        if response == Gtk.ResponseType.YES:
            Gtk.main_quit()

    def on_close(self, widget, event):
        """Handle window close"""
        return True  # Prevent closing during installation

def main():
    # Check if running as root
    if os.geteuid() != 0:
        print("Error: Installer must be run as root")
        sys.exit(1)

    # Check if in live mode
    if not os.path.exists('/run/icenet/live-boot'):
        print("Error: Installer must be run from live boot")
        sys.exit(1)

    win = InstallerWindow()
    win.show_all()
    Gtk.main()

if __name__ == '__main__':
    main()
