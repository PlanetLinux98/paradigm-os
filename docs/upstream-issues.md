# Upstream issue drafts — Anaconda Web UI (found testing builds 6-7, 2026-07-11/16)

Four findings from Elliott's UEFI install tests of ParadigmOS builds 6-7
(Fedora 44 base, anaconda-44.30-2.fc44, anaconda-webui-68-1.fc44), all
upstream Anaconda Web UI behavior, none remix-specific.

**Where to file:** Red Hat Bugzilla (https://bugzilla.redhat.com/enter_bug.cgi),
product **Fedora**, component **anaconda-webui** (fall back to **anaconda**
if the component doesn't exist), version **44**. GitHub issues are disabled
on both rhinstaller/anaconda and rhinstaller/anaconda-webui — Bugzilla is
the tracker, matching the installer's own crash-report flow.

**Duplicate check:** quicksearch for open Fedora/anaconda bugs mentioning
"orca" or "accessibility" came back empty (2026-07-11), but re-check from
the bug entry form, which live-suggests duplicates from the summary line.

Status: DRAFTS — not filed. Elliott reviews first.

---

## Draft 1 — No access keys / keyboard shortcuts on primary navigation buttons

**Summary:** Web UI: Next/Back buttons have no access keys or announced
keyboard shortcuts, forcing screen-reader users to Tab-cycle the whole page

**Description:**

The GTK Anaconda UI gave its primary actions mnemonics (Alt+underlined
letter), announced by Orca. The Web UI's wizard navigation buttons — Next,
Back, and the other footer actions — expose no access keys, no
`aria-keyshortcuts`, and no application-level shortcuts. A keyboard or
screen-reader user must Tab through every control on the page (or use
Orca browse-mode structural navigation, which not all users know) just to
advance to the next step, on every step of the install.

Steps to reproduce:
1. Boot a Fedora 44 Workstation live image with Orca running.
2. Start the installer and navigate using only Tab/Shift+Tab and arrows.
3. Try to activate Next/Back without Tab-cycling to them.

Actual: no shortcut exists; nothing is announced by Orca beyond the plain
button name when focused.

Expected: primary wizard actions reachable via a documented shortcut
(e.g. HTML `accesskey` or app-level handler), exposed to AT via
`aria-keyshortcuts` so Orca announces it.

Environment: anaconda-44.30-2.fc44, anaconda-webui-68-1.fc44, live UEFI
install, Orca from the live session. (Observed on a Fedora 44 remix,
ParadigmOS; the UI code paths are stock anaconda-webui.)

---

## Draft 2 — No type-ahead / first-letter navigation in list widgets

**Summary:** Web UI: lists (language, keyboard, disk selection, etc.) have
no type-ahead or first-letter navigation

**Description:**

The GTK Anaconda treeviews supported interactive search: typing jumped to
the matching row. In the Web UI, none of the list widgets respond to
typing — reaching an entry deep in a long list (a language, a timezone, a
disk) requires arrowing item by item. This is slow for everyone and
especially costly for screen-reader users, who must listen to each item
announced along the way.

Steps to reproduce:
1. Boot a Fedora 44 Workstation live image, start the installer.
2. Focus the language list on the first step.
3. Type a letter (e.g. "s" hoping to reach "Svenska").

Actual: keystrokes are ignored; only arrow keys move the selection.

Expected: first-letter navigation at minimum; ideally the searchable/
typeahead PatternFly select variant for long lists.

Environment: anaconda-44.30-2.fc44, anaconda-webui-68-1.fc44, live UEFI
install, Orca from the live session.

---

## Draft 3 — Critical-error dialog wording implies network is required to install

**Summary:** Web UI: "Network not available" line in the installation-failed
dialog reads as the cause of the failure, not as a bug-reporting requirement

**Description:**

When installation fails without a network connection, the error dialog
shows, immediately under the failure headline:

    Installation of the system failed: Installing boot loader
    Network not available. Configure the network in the top bar menu to
    report the issue.

The network line belongs to the Bugzilla crash-report flow, but its
placement and phrasing make it read as the reason the install failed. A
real user (this report comes from exactly this experience) quit the
installer, connected to Wi-Fi, and re-ran the entire installation believing
a network connection was a hard requirement — only to hit the same
unrelated bootloader error with the network up.

Suggested fix: move the network hint into the reporting section of the
dialog and reword it, e.g. "To report this issue to Bugzilla, first
connect to a network using the top bar menu." Keep the failure description
and the reporting instructions visually and semantically separate (also
helps screen-reader users, who hear the dialog linearly).

Environment: anaconda-44.30-2.fc44, anaconda-webui-68-1.fc44, live UEFI
install.

---

## Draft 4 — RFE: Restart button on the installation-complete screen (live installs)

**Summary:** Web UI: completion screen tells the user to reboot but offers
no Restart action and no hint where restarting lives

**Description:**

After a successful live install, the final screen says "To begin using
<product>, reboot your system." next to an "Exit to live desktop"-style
button — but there is no Restart/Reboot button, and the message doesn't
say how to restart. A newcomer (or a screen-reader user navigating an
unfamiliar desktop) has to go find GNOME's system menu on their own to
finish the single action the installer just asked of them. The old GTK
UI's live flow had the same gap, so this is a request to do better, not a
regression report.

Suggested fix, in order of preference:
1. Add a "Restart system" button beside the exit-to-desktop action on the
   completion screen (the session can request reboot via logind).
2. Failing that, make the message actionable, e.g. "…restart your system:
   press Ctrl+Alt+Delete and choose Restart."

(Downstream we currently patch option 2's wording into the English bundle;
a real button would let us drop that.)

Environment: anaconda-44.30-2.fc44, anaconda-webui-68-1.fc44, live UEFI
install.
