#!/usr/bin/python3
"""ParadigmOS accessibility quick settings.

Shown automatically on a user's first login after installing ParadigmOS
(launched with --autostart from /etc/xdg/autostart), and available any time
from the app grid as "Accessibility Quick Settings". Every switch applies
immediately via GSettings — the same keys GNOME Settings > Accessibility
writes — so nothing here invents new mechanisms; it only surfaces the
essentials up front, which the spec requires ("text size and display
scaling surfaced prominently, not buried in Settings").

Master copy: apps/a11y-setup/ in the repo. A copy is embedded in
kickstart/paradigmos.ks %post — keep the two in sync.
"""

import os
import pwd
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

APP_ID = "org.paradigmos.A11ySetup"
STAMP = os.path.join(GLib.get_user_config_dir(), "paradigmos", "a11y-setup-shown")

LARGE_TEXT_FACTOR = 1.25
NORMAL_TEXT_FACTOR = 1.0
LARGE_CURSOR_SIZE = 48
NORMAL_CURSOR_SIZE = 24


def is_live_session():
    """The live image should not nag: the app only autostarts on installed
    systems. (Manual launches from the app grid work anywhere.)"""
    try:
        pwd.getpwnam("liveuser")
        return True
    except KeyError:
        return False


class Window(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Accessibility")
        self.set_default_size(560, 660)

        self.a11y_apps = Gio.Settings.new("org.gnome.desktop.a11y.applications")
        self.a11y_iface = Gio.Settings.new("org.gnome.desktop.a11y.interface")
        self.iface = Gio.Settings.new("org.gnome.desktop.interface")

        page = Adw.PreferencesPage()
        group = Adw.PreferencesGroup(
            title="Welcome to ParadigmOS",
            description=(
                "Choose the accessibility features you need. Everything "
                "applies immediately and can be changed at any time in "
                "Settings › Accessibility."
            ),
        )
        page.add(group)

        group.add(self._bound_row(
            "Screen Reader",
            "Speak items on the screen (Orca). Toggle any time with Super+Alt+S",
            self.a11y_apps, "screen-reader-enabled"))
        group.add(self._bound_row(
            "Magnifier",
            "Zoom in on the whole screen",
            self.a11y_apps, "screen-magnifier-enabled"))
        group.add(self._bound_row(
            "On-Screen Keyboard",
            "Type without a physical keyboard",
            self.a11y_apps, "screen-keyboard-enabled"))
        group.add(self._bound_row(
            "High Contrast",
            "Make text and interface outlines stand out",
            self.a11y_iface, "high-contrast"))

        self.text_row = Adw.SwitchRow(
            title="Large Text", subtitle="Increase the size of all text")
        self.text_row.set_active(
            self.iface.get_double("text-scaling-factor")
            >= LARGE_TEXT_FACTOR - 0.01)
        self.text_row.connect("notify::active", self._on_large_text)
        group.add(self.text_row)

        self.cursor_row = Adw.SwitchRow(
            title="Large Pointer", subtitle="Make the mouse pointer easier to see")
        self.cursor_row.set_active(
            self.iface.get_int("cursor-size") >= LARGE_CURSOR_SIZE)
        self.cursor_row.connect("notify::active", self._on_large_cursor)
        group.add(self.cursor_row)

        self.anim_row = Adw.SwitchRow(
            title="Reduce Animation", subtitle="Minimise on-screen motion")
        self.anim_row.set_active(not self.iface.get_boolean("enable-animations"))
        self.anim_row.connect("notify::active", self._on_reduce_animation)
        group.add(self.anim_row)

        more = Gtk.Button(label="All Accessibility Settings…")
        more.set_tooltip_text("Open the full Accessibility page in Settings")
        more.connect("clicked", self._on_open_settings)

        done = Gtk.Button(label="_Done", use_underline=True)
        done.add_css_class("suggested-action")
        done.connect("clicked", lambda *_: self.close())

        actions = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12,
                          halign=Gtk.Align.CENTER,
                          margin_top=12, margin_bottom=18)
        actions.append(more)
        actions.append(done)

        view = Adw.ToolbarView()
        view.add_top_bar(Adw.HeaderBar())
        view.set_content(page)
        view.add_bottom_bar(actions)
        self.set_content(view)

    def _bound_row(self, title, subtitle, settings, key):
        row = Adw.SwitchRow(title=title, subtitle=subtitle)
        settings.bind(key, row, "active", Gio.SettingsBindFlags.DEFAULT)
        return row

    def _on_large_text(self, row, _pspec):
        self.iface.set_double(
            "text-scaling-factor",
            LARGE_TEXT_FACTOR if row.get_active() else NORMAL_TEXT_FACTOR)

    def _on_large_cursor(self, row, _pspec):
        self.iface.set_int(
            "cursor-size",
            LARGE_CURSOR_SIZE if row.get_active() else NORMAL_CURSOR_SIZE)

    def _on_reduce_animation(self, row, _pspec):
        self.iface.set_boolean("enable-animations", not row.get_active())

    def _on_open_settings(self, _button):
        Gio.AppInfo.create_from_commandline(
            "gnome-control-center universal-access", None,
            Gio.AppInfoCreateFlags.NONE).launch([], None)


class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID)

    def do_activate(self):
        win = self.props.active_window
        if not win:
            win = Window(self)
        win.present()


def main():
    argv = list(sys.argv)
    autostart = "--autostart" in argv
    if autostart:
        argv.remove("--autostart")
        if is_live_session() or os.path.exists(STAMP):
            return 0
        # Stamp immediately: the welcome pass is once per user, full stop.
        os.makedirs(os.path.dirname(STAMP), exist_ok=True)
        with open(STAMP, "w", encoding="utf-8") as f:
            f.write("shown\n")
    return App().run(argv)


if __name__ == "__main__":
    sys.exit(main())
