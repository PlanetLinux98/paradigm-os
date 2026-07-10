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

## Current status (update this section as work proceeds — last: 2026-07-10)

Done: spec finalized (v0.4); repo public at PlanetLinux98/paradigm-os; first
kickstart draft (`kickstart/paradigmos.ks`) and containerized build script
committed. Mark decided: "Shifted tile" (branding/icons/paradigmos-mark.svg),
three-tone per Elliott: dark navy P-tiles #1A3F5F, lighter grid tiles
#4A8ABD, teal escapee. The kickstart embeds a copy — keep them in sync.
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

Elliott's decisions 2026-07-10 (second round): mark tones nudged again —
P-tiles darker (#1A3F5F), grid tiles lighter (#4A8ABD); wallpaper set 1
(aurora-1) APPROVED, wants 3-4 more sets of varying design; accent colour
is GNOME's built-in `teal`, and the brand teal was realigned to match it
exactly (#1B8A90 → #2190A4 everywhere, companion tints shifted too).
accent-color='teal' is in the kickstart dconf. Standing art direction:
grounds must avoid pure white/black and carry real colour, blue included.

Awaiting Elliott: reaction to wallpaper proposal sets 2-5 in
branding/wallpapers/ (shift, headland, ripple, curtain — light+dark each)
and to the optional stronger mark-contrast variant (P #15334E, grid
#5A99C9) offered alongside the applied one.

Next up (in order):
1. Elliott picks wallpaper sets + mark strength; wire picks into the
   kickstart (gnome-background-properties entries for extra sets).
2. VM install test (Anaconda flow + a11y carry-over, see above).
3. Resolve kickstart `TODO(...)` markers (NVIDIA strategy, Anaconda branding
   hooks, GNOME theme + high-contrast variant, Plymouth, snapshot tooling,
   backgrounds RPM instead of build-time curl).

Deferred by design: website/domain (~v1); update cadence (post-v1, leaning
12-month major cycle).
