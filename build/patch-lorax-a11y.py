#!/usr/bin/env python3
"""Insert the ParadigmOS screen-reader boot entry into lorax's live GRUB templates.

Runs inside the build container (see build/build-iso.sh) after lorax is
installed and before livemedia-creator, so the generated ISO's BIOS and UEFI
menus both carry the entry and the implanted media checksum stays valid.
Fedora 44's live templates use GRUB2 for BIOS as well as UEFI (isolinux is
gone), so the same patch covers both boot paths.

The entry is a copy of the plain "Start" entry plus the kernel argument
paradigmos.a11y=screenreader, which paradigmos-a11y-boot.service (defined in
the kickstart %post) turns into a speaking GNOME session. --hotkey=s means a
blind user presses "s" at the menu -- no arrow keys, no sight -- and boots
straight into it. The entry goes AFTER the "Test this media" entry so the
templates' `set default="1"` still points at the media check, and pressing
Down once from the default also lands on it.

A further tweak for users who can't see the menu (Elliott, 2026-07-10): the
menu announces itself with two short PC-speaker beeps (the same figure
Debian's accessible images play). The beep is guarded -- where the play
module is unavailable (e.g. Fedora's signed UEFI grub, which can't load
unsigned modules under Secure Boot) or no PC speaker exists, it is a silent
no-op. The autoboot timeout stays at lorax's stock 60s: it was doubled to
120s in builds 5-7, and Elliott judged 60s enough after real install
testing (2026-07-16). Any keypress still freezes the countdown.
"""

import re
import sys
from pathlib import Path

TEMPLATE_DIR = Path("/usr/share/lorax/templates.d/99-generic/live/config_files/x86")
CONFIGS = ["grub2-bios.cfg", "grub2-efi.cfg"]

START_TITLE = "menuentry 'Start @PRODUCT@ @VERSION@'"
A11Y_TITLE = (
    "menuentry 'Start @PRODUCT@ @VERSION@ with screen reader (press S)' --hotkey=s"
)
KERNEL_ARG = "paradigmos.a11y=screenreader"

START_BLOCK = re.compile(r"^menuentry 'Start @PRODUCT@ @VERSION@' .*?^\}\n", re.S | re.M)
TEST_BLOCK = re.compile(r"^menuentry 'Test this media.*?^\}\n", re.S | re.M)

TIMEOUT_OLD = "set timeout=60"
TIMEOUT_NEW = """set timeout=60

# Audible cue that the boot menu is on screen -- two short beeps, the same
# figure Debian's accessible images use -- so a blind user knows the moment
# the s hotkey (screen-reader session) is available. Guarded: a silent no-op
# where the play module is unavailable or no PC speaker exists.
if insmod play; then
  play 960 440 1 0 4 440 1
fi"""


def patch(path: Path) -> None:
    text = path.read_text()
    if KERNEL_ARG in text:
        print(f"{path}: already patched, skipping")
        return

    start = START_BLOCK.search(text)
    if not start:
        sys.exit(f"{path}: no plain 'Start' menuentry found — lorax template changed?")
    entry = start.group(0).replace(START_TITLE, A11Y_TITLE, 1)
    entry, n = re.subn(r"rd\.live\.image", f"rd.live.image {KERNEL_ARG}", entry, count=1)
    if n != 1:
        sys.exit(f"{path}: 'Start' entry has no rd.live.image argument to anchor on")

    test = TEST_BLOCK.search(text)
    if not test:
        sys.exit(f"{path}: no 'Test this media' menuentry found — lorax template changed?")
    text = text[: test.end()] + entry + text[test.end() :]

    if TIMEOUT_OLD not in text:
        sys.exit(f"{path}: no '{TIMEOUT_OLD}' line — lorax template changed?")
    text = text.replace(TIMEOUT_OLD, TIMEOUT_NEW, 1)

    path.write_text(text)
    print(f"{path}: screen-reader entry and menu beep added (timeout stays 60s)")


for name in CONFIGS:
    patch(TEMPLATE_DIR / name)
