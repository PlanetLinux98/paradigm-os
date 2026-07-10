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
committed. Mark decided: "Shifted tile" (branding/icons/paradigmos-mark.svg)
with five darker tiles tracing a subtle P — Elliott's own refinement idea.
Two earlier concepts (literal letter-P; aurora-ring/horizon-shift alternates)
were rejected — don't resurrect them.

**FIRST ISO BUILT 2026-07-10**: ParadigmOS-1.0-Aurora-x86_64.iso (2.7 GB),
after 5 attempts (fixes each documented in git log: dracut-live, stale result
dir, url install method, rootpw --lock). Built in /root/paradigm-os inside
WSL (build there, NOT /mnt/c — drvfs breaks loop mounts; sync via
`git pull /mnt/c/Users/Elliott/ParadigmOS main`). Copy of ISO at
build/output/ on the Windows side (gitignored). QEMU/KVM smoke test works
inside WSL (qemu-system-x86, socat, imagemagick installed).

Awaiting Elliott: reaction to the darker-P-tile shading and to the third
wallpaper colour pass (light draft 3, dark draft 2). Standing art direction:
grounds must avoid pure white/black and carry real colour, blue included.

Next up (in order):
1. Finalize mark + wallpaper from Elliott's picks; more wallpaper variants.
2. Resolve kickstart `TODO(...)` markers (NVIDIA strategy, Anaconda branding
   hooks, GNOME theme + high-contrast variant, Plymouth, snapshot tooling,
   backgrounds RPM instead of build-time curl).
3. First ISO build + VM test-boot: verify Orca from boot menu, install flow,
   branding. Expect iteration.

Deferred by design: website/domain (~v1); update cadence (post-v1, leaning
12-month major cycle).
