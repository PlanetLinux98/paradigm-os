# ParadigmOS — context for Claude sessions

ParadigmOS is Elliott's public, accessibility-first Linux distribution: a Fedora
remix (currently Fedora 44 base) with GNOME, general-purpose daily-driver focus.
Started 2026-07-09.

## Read first

- **`docs/SPEC.md` is the source of truth** for every project decision (base,
  branding, apps, installer, governance). Read it before proposing or changing
  anything. Update it when decisions change.
- The styled spec lives as a Claude Artifact:
  https://claude.ai/code/artifact/b61892f9-ce9b-4528-8808-f3e4f116d53c
  (update it alongside SPEC.md when working in a session that can).

## Non-negotiable requirement

Any user, sighted or not, must be able to install and use the system from the
very first step: Orca reachable from the boot menu before the installer starts,
working speech/braille in the live session, text-size/scaling surfaced in
first-run setup. This drove Anaconda over Calamares. Never trade this away for
visual polish.

## Working style

- Elliott is a distro-building beginner: Claude does the technical work and
  explains briefly; Elliott makes creative/identity calls. Present visual
  options rather than iterating one guess at a time.
- Public-facing actions (pushing, releases) are fine for this repo; Elliott's
  GitHub is PlanetLinux98, gh CLI is authenticated.
- Windows machine. Build env: Docker Engine inside WSL2 `Ubuntu-24.04`
  (systemd enabled). ISO builds: `bash build/build-iso.sh` (runs
  livemedia-creator in a fedora:44 container). Keep `.sh`/`.ks` files LF
  (enforced by .gitattributes).

## Current status (update this section as work proceeds — last: 2026-07-11)

Done: spec finalized (v0.4); repo public at PlanetLinux98/paradigm-os; first
kickstart draft (`kickstart/paradigmos.ks`) and containerized build script
committed. Mark decided: "Shifted tile" (branding/icons/paradigmos-mark.svg),
three-tone per Elliott: dark navy P-tiles #1F4A6E, lighter grid tiles
#4A8ABD, teal escapee #2190A4. MARK SETTLED 2026-07-10 (two rounds:
Elliott kept the original P shade, lightened only the grid tiles).
The kickstart embeds a copy — keep them in sync.
Three-tone mark confirmed on-screen in build 3 (welcome dialog + dock).
Two earlier concepts (literal letter-P; aurora-ring/horizon-shift alternates)
were rejected — don't resurrect them.

**FIRST ISO BUILT AND BOOT-TESTED 2026-07-10**: ParadigmOS-1.0-Aurora-x86_64.iso
(2.7 GB), after 5 attempts (fixes each documented in git log: dracut-live,
stale result dir, url install method, rootpw --lock). Built in
/root/paradigm-os inside WSL (build there, NOT /mnt/c — drvfs breaks loop
mounts; sync via `git pull /mnt/c/Users/Elliott/ParadigmOS main`). ISO copy
at build/output/ on the Windows side (gitignored). QEMU/KVM smoke test:
`bash build/smoke-test.sh` inside WSL (screenshots in docs/screenshots/).

**BUILD 2 VERIFIED 2026-07-10** (screenshots in docs/screenshots/build2-*):
boot menu "Start ParadigmOS 1.0"; aurora wallpaper applied (dconf profile
fix worked); shifted-tile logo shows in welcome dialog + dock (hot dog
retired). Locale now en_CA.UTF-8 + America/Toronto (Elliott's decision).
Kickstart is hermetic — SVG assets embedded in %post, keep in sync with
branding/ (TODO: move to paradigmos-{backgrounds,logos} RPMs by v1).

**BUILD 3 VERIFIED 2026-07-10 — FLAGSHIP ACCESSIBILITY ENTRY SHIPPED**
(screenshots docs/screenshots/build3-*, speech proof build3-orca-speech.ogg):
boot menus (BIOS+UEFI, both GRUB2 — F44 lorax dropped isolinux) carry
"Start ParadigmOS 1.0 with screen reader (press S)", hotkey `s`, inserted
by build/patch-lorax-a11y.py at build time. It adds kernel arg
paradigmos.a11y=screenreader; paradigmos-a11y-boot.service (kickstart
%post) flips the GNOME screen-reader default before GDM starts. QEMU
smoke test now records guest audio and FAILED-if-silent: build 3 captured
26s of real Orca speech (peak 29970/32767). An anaconda post-script
(/usr/share/anaconda/post-scripts/70-paradigmos-a11y.ks) carries the
setting onto installed systems — that install path is NOT yet tested (no
VM install run yet). Build-3 gotchas now guarded in the build script:
pykickstart parses %-section lines even inside heredocs (use @POST@/@END@
placeholders + sed), and ksvalidator needs the pykickstart package.

Remaining known work:
- Test the install flow in a VM: Anaconda + Orca, and that the a11y
  post-script really carries speech onto the installed system.
- GNOME theme pass (branded + high-contrast variants); Plymouth splash;
  NVIDIA driver strategy; snapshot tooling (snapper/btrfs-assistant).
- pkill gotcha: never `pkill -f qemu...` from a wsl.exe bash -lc one-liner
  (pattern matches the shell's own cmdline and self-terminates, exit 15).
- Background processes (qemu) do not survive the wsl.exe session ending —
  take all VM screenshots within the same script run.

Elliott's decisions 2026-07-10: mark settled (P stays #1F4A6E, grid
lightened to #4A8ABD — he tried the darker-P variant and reverted it);
wallpaper set 1 (aurora-1) APPROVED, wants 3-4 more sets of varying
design; accent colour is GNOME's built-in `teal`, and the brand teal was
realigned to match it exactly (#1B8A90 → #2190A4 everywhere, companion
tints shifted too). accent-color='teal' is in the kickstart dconf.
Standing art direction: grounds must avoid pure white/black and carry
real colour, blue included.

WALLPAPERS SETTLED 2026-07-10: all five sets approved after three revision
rounds (rev 2: teal shift-light ground, melting headland layers, more
vivid ripple/curtain; rev 3: shift/headland/ripple fill the frame). All
eight new SVGs embedded in the kickstart (via scratch script reading
branding/wallpapers/ so copies can't drift) and registered in
gnome-background-properties as Shift/Aurora/Headland/Ripple/Curtain.
SHIFT is the dconf default since build 8 (Elliott 2026-07-16; Aurora was
the default builds 2-7), and the stock GNOME/Fedora wallpaper XMLs are
deleted in %post so Settings > Appearance offers only our five.

**BUILD 4 VERIFIED 2026-07-10** (screenshots docs/screenshots/build4-*):
teal accent CONFIRMED — the welcome dialog's Install button renders GNOME
teal instead of stock blue; settled mark confirmed in dialog + dock;
Aurora default wallpaper applied; screen-reader boot entry regression
passed with 25s of Orca speech captured. Not visually verified (mechanism
trusted): the five sets appearing in Settings > Appearance — check during
the VM install test session.

**BUILD 5 VERIFIED 2026-07-11** — boot-menu a11y round 2 (Elliott's
concerns): GRUB beeps twice when the menu appears (Debian's figure,
`play 960 440 1 0 4 440 1`, guarded insmod) and the timeout doubled to
120s (countdown confirmed on-screen). Smoke test wires the emulated PC
speaker into the wav capture (-machine pcspk-audiodev) and prints
per-segment timestamps: build 5 shows the beep blip at capture start +
Orca speech later — BEEP CUE DETECTED, SPEECH CHECK PASSED. Beep check
is informational, speech check still hard-fails. Beep caveat: needs the
play module + PC speaker — BIOS machines and VMs yes, signed-UEFI
hardware mostly no (the 120s timeout is the net there).

Build stamping (Elliott 2026-07-11): every ISO self-identifies — BUILD_ID
in os-release (N.YYYYMMDD.g<hash>; N from build/BUILD_NUMBER, bump it per
verified build), boot title "(build N)", ISO filename/volid buildN,
/etc/paradigmos-release one-liner. build-iso.sh fills @BUILDID@/@BUILDINFO@
placeholders into a stamped kickstart copy under build/output/ — repo
kickstart keeps the placeholders. Spell out "build N", never "bN" (reads
as beta). First stamped build: 6. Verify Settings > About shows "OS Build"
during the VM session.

**BUILD 6 VERIFIED 2026-07-11 — FIRST STAMPED BUILD** (screenshot
docs/screenshots/build6-boot-menu.png): boot menu reads "Start
ParadigmOS 1.0 (build 6)" on every entry; ISO filename
ParadigmOS-1.0-Aurora-build6-x86_64.iso; beep + speech checks passed
again. BUILD_ID/paradigmos-release inside the image use the same
stamped kickstart (mechanism verified via the boot title); the Settings
> About "OS Build" row still needs an eyeball in the VM session.

**BUILD 7 VERIFIED 2026-07-11 — UEFI INSTALL CRASH FIXED** (screenshots
docs/screenshots/build7-*): Elliott's build-6 UEFI install test died at
"Installing boot loader" with "gen_grub_cfgstub script failed". Root
cause: the os-release rebrand (ID=paradigmos) broke anaconda PROFILE
DETECTION — it matches ID/VARIANT_ID exactly, ID_LIKE is ignored — so no
profile loaded, efi_dir fell back to "default", and /usr/bin/gen_grub_cfgstub
(grub2's ESP-stub writer, run chrooted by anaconda's EFIGRUB.write_config)
tried to write into the nonexistent /boot/efi/EFI/default. Losing the
profile ALSO silently dropped Btrfs-default partitioning, GRUB
menu_auto_hide, and the Workstation installer stylesheet. Fix: kickstart
%post now ships /etc/anaconda/profile.d/paradigmos.conf (os_id=paradigmos,
base_profile=fedora-workstation → fedora; efi_dir must stay "fedora" —
signed shim's baked-in path). Verified by chrooting into the built
squashfs and running anaconda's real detection code: efi_dir=fedora,
default_scheme=BTRFS. Boot menu shows "(build 7)"; beep + speech smoke
checks passed. The end-to-end UEFI install itself still needs Elliott's
VM re-test. Red herring, for the record: the first failure's "Network
not available… to report the issue" line is the web UI's Bugzilla
crash-report flow — installs need NO network; same bootloader error both
times.

Upstream (from the same test session): three Bugzilla drafts in
docs/upstream-issues.md awaiting Elliott's review — anaconda-webui has no
button access keys and no list type-ahead (real a11y gaps vs old GTK UI),
plus the misleading network line above. GitHub issues are DISABLED on
rhinstaller/anaconda{,-webui}; file at bugzilla.redhat.com, product
Fedora, component anaconda-webui. Orca workaround worth documenting for
users: the installer is web content, so browse-mode structural nav works
(B = next button, F = form field). Open decision for Elliott: inherited
menu_auto_hide means installed systems skip the GRUB menu on healthy
boots (stock Fedora behavior) — decide whether installed ParadigmOS
should instead show the menu with the beep cue like the live ISO.

WSL/tooling gotchas (cost real debugging time 2026-07-11):
- `wsl.exe ... bash -c "..."` one-liners: $variables are expanded by the
  OUTER WSL shell pass-through and arrive empty inside bash (an early
  mount "failed" because $ISO was empty). Put anything non-trivial in a
  script file and run `wsl.exe bash /mnt/c/...` — but launch that from
  PowerShell, not Git Bash (MSYS mangles /mnt/... args into
  C:/Program Files/Git/...).
- Loop mounts inside WSL do NOT persist between wsl.exe invocations
  (the utility VM idles out) — mount, work, and unmount in one script.
- chroot python into the squashfs needs /dev bind-mounted (pyudev's
  find_library dies on missing /dev/null).

**BUILD 8 VERIFIED 2026-07-16 — INSTALL-TEST FEEDBACK ROUND** (build 7
install SUCCEEDED in Elliott's UEFI VM; screenshots docs/screenshots/
build8-*). Eight feedback items, all landed except one deferred:
1. Installer app icon was a generic cog: liveinst.desktop wants
   Icon=org.fedoraproject.AnacondaInstaller, which NOTHING ships as an
   icon — mark now installed under that name (+ anaconda's own name;
   stock fixed-size PNGs removed so the SVG serves all sizes).
2. Webui completion message now says HOW to restart ("press
   Ctrl+Alt+Delete and activate Restart") — English string patched via
   gunzip/sed/gzip of index.js.gz in %post, verification greps for it so
   an upstream msgid change can't silently ship stale wording; proper
   Restart-button RFE is draft 4 in docs/upstream-issues.md.
3. ROOT CAUSE of Orca silent at first-boot setup: gnome-initial-setup's
   dconf profile (/usr/share/dconf/profile/gnome-initial-setup) does NOT
   chain system-db:local, so the carried screen-reader flag (and ALL our
   dconf defaults) were invisible there. /etc/dconf/profile/
   gnome-initial-setup override (adds system-db:local) ships now; GDM's
   profile already chained local. Carry-over trigger also broadened:
   kernel arg OR the live user's screen-reader-enabled gsetting (catches
   Orca toggled manually via Super+Alt+S before installing).
4. fedora-third-party enable baked at build → g-i-s skips its
   Third-Party Repositories page; Chrome repo, NVIDIA driver + Steam
   (RPM Fusion nonfree), PyCharm copr, unfiltered Flathub on by default.
5. Default wallpaper is now Shift; only our five sets in Settings.
6. Min/max window buttons on, hot corner off, accessibility menu always
   shown — note the REAL key for the menu is org/gnome/desktop/a11y
   always-show-universal-access-status (builds ≤7 wrongly assumed
   toolkit-accessibility did this).
7. Live GRUB timeout back to stock 60s (120s judged unnecessary).
8. A11y preferences screen during install/setup: exists in NEITHER
   anaconda-webui nor gnome-initial-setup upstream — deferred; options
   scoped for Elliott (own first-boot a11y quick-settings app would also
   satisfy the spec's "text size in first-run setup" requirement).
All items verified inside the built image (icon SVGs, bundle string,
dconf keys, third-party state, single wallpaper XML, timeout+beep in
grub.cfg, BUILD_ID 8.20260716.g9d04eef); beep + speech smoke checks
passed; desktop screenshot shows Shift wallpaper + branded installer
icon in the dock. Build gotcha fixed in build-iso.sh: fedora-cisco-
openh264 (enabled by default in the fedora container, Cisco's host
times out routinely) killed the first build-8 run — the toolchain dnf
now runs --disablerepo=fedora-cisco-openh264; the image never used it.

**BUILD 9 BUILT + IN-IMAGE VERIFIED 2026-07-17** — Elliott's build-8 test
feedback round: stock wallpapers restored with our five pinned to the top
of Settings > Appearance (leading-space names — the panel sorts by plain
strcmp on <name>, invisible in the caption-less grid, ignored by screen
readers; Shift gets two spaces to sort first); Ctrl+Alt+Delete rebound to
GNOME's power dialog (stock GNOME binds it to a Log Out prompt with no
Restart — the installer's completion message now tells the truth; SPEC
row added); boot-menu cue is now THREE beeps (Morse "S"; GRUB cannot
reach a sound card and signed-UEFI GRUB can't load the play module, so no
cue is physically possible on most modern laptops — documented in SPEC);
g-i-s Third-Party page skipped via vendor.conf [pages] skip=software
(ROOT CAUSE found in gis-software-page.c: the page shows whenever the
fedora-third-party BINARY exists, never reads the recorded state, and its
button always starts "off" — leaving it off changes nothing, so build 8's
baked enable was working all along and the page was pure noise); NEW
"Accessibility Quick Settings" app (apps/a11y-setup/, GTK4/libadwaita,
embedded in kickstart %post): screen reader / magnifier / on-screen
keyboard / high contrast / large text / large pointer / reduce animation,
opens once per user on first login into an INSTALLED system (never in
live), permanently in the app grid — delivers the spec's "text size in
first-run setup" requirement.

**AUTOMATED INSTALL TEST HARNESS (build/install-test.sh) — WORKING
2026-07-17.** Run inside WSL: `bash build/install-test.sh [outdir] [iso]`.
Three phases: (1) unattended kickstart install driven over serial (root
debug shell on ttyS1, anaconda --text TUI walked by a python driver;
LIVECMD override + PKEXEC_UID export + dbus-run-session + webui dir
hidden in the guest overlay — see the script's comments for WHY each is
needed); (2) first boot of the installed disk with audio capture +
screenshots; (3) live-boot mount of the installed disk and file
inspection. FINDINGS from the first full run (build 9 disk):
- WORKING on a real installed system: Btrfs autopart layout (600M ESP +
  2G ext4 /boot + btrfs), the ESP grub stub (the build-7 bootloader fix,
  now proven through an actual install), third-party state
  "[main] enabled = yes" SURVIVES install intact, vendor.conf page skip,
  g-i-s dconf profile override, BUILD_ID stamp.
- BROKEN AND NOW ROOT-CAUSED: the a11y carry-over post-script NEVER ran —
  /usr/share/anaconda/post-scripts is dead code in anaconda 44
  (appendPostScripts has no callers). Builds 3-9's carry-over silently
  did nothing; Elliott's manual observations were accurate.

**BUILD 10 (in progress 2026-07-17) — REAL carry-over fix**: the
paradigmos anaconda profile now sets [Bootloader] preserved_arguments =
stock list + paradigmos.a11y, so anaconda itself copies the
accessible-boot kernel arg onto the installed bootloader (same whitelist
that preserves console= and speakup_synth; verified the stock list from
/etc/anaconda/anaconda.conf and that unlisted args get dropped).
paradigmos-a11y-boot.service (enabled in the image → enabled on installed
copies, ConditionKernelCommandLine, logs to
/var/log/paradigmos-a11y-boot.log) flips the screen-reader default before
GDM on first boot. Dead post-script removed. Known limitation: Orca
toggled MANUALLY in the live session (no kernel arg) does not carry over
(it never did); the first-login a11y app is the fallback. VERIFY in the
install test: BLS options contain paradigmos.a11y=screenreader, and
phase-2 firstboot audio shows speech at gnome-initial-setup.

WSL/QEMU harness gotchas (2026-07-17, cost real time):
- The WSL VM has 7 GB RAM: run builds, smoke tests, and install tests
  SERIALLY, never in parallel (a parallel smoke test's cleanup pkill
  also murdered an install VM mid-run before its pattern was scoped).
- Background processes die when their wsl.exe invocation exits — a
  harness must do everything in one invocation, and killing a harness
  script kills its VM.
- anaconda TUI/webui specifics (PKEXEC_UID, LIVECMD, cmdline-mode race,
  "Press ENTER to quit") are documented inline in install-test.sh.

Next up (in order):
1. Finish build 10 verification: in-image checks + full install test
   (expect BLS arg + SPEECH at first boot) + smoke test; copy ISO to
   build/output/ on the Windows side.
2. VM install re-test with build 10 (Elliott, manual): the accessible
   path end-to-end — S-entry boot, webui install, first boot should
   speak at Setup — plus the build-9 UI items: wallpapers (ours first,
   stock present), Ctrl+Alt+Delete restart flow, three beeps, no
   third-party page in setup, Accessibility Quick Settings on first
   login, Settings > About "OS Build" row.
3. Review + file the FOUR Bugzilla drafts (docs/upstream-issues.md).
4. Decide: installed-system GRUB menu_auto_hide
   (currently inherited Fedora behavior: menu hidden on healthy boots).
4. Resolve kickstart `TODO(...)` markers (NVIDIA strategy, Anaconda branding
   hooks, GNOME theme + high-contrast variant, Plymouth, snapshot tooling,
   backgrounds RPM instead of build-time curl).

Deferred by design: website/domain (~v1); update cadence (post-v1, leaning
12-month major cycle).
