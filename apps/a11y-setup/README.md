# Accessibility Quick Settings (paradigmos-a11y-setup)

A small GTK4/libadwaita app that surfaces the essential accessibility
switches — screen reader, magnifier, on-screen keyboard, high contrast,
large text, large pointer, reduce animation — writing the same GSettings
keys GNOME Settings uses.

Two entry points on the installed system:

- **First login:** `/etc/xdg/autostart/org.paradigmos.A11ySetup-firstboot.desktop`
  runs `paradigmos-a11y-setup --autostart`, which shows the window once per
  user (stamp: `~/.config/paradigmos/a11y-setup-shown`) and never in the
  live session.
- **Any time:** "Accessibility Quick Settings" in the app grid.

This delivers the spec's first-run requirement: text size / display
scaling surfaced prominently, not buried in Settings.

The kickstart (`kickstart/paradigmos.ks` %post) embeds a copy of
`paradigmos-a11y-setup.py` and both .desktop files — **keep them in sync**
until the planned paradigmos RPMs exist (TODO(packaging)).
