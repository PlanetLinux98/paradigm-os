# ParadigmOS — Project Specification (Draft v0.1)

Compiled 2026-07-10 from the initial planning conversation. A styled version of this
document (with color swatches and the wordmark concept) was published as a Claude
Artifact during planning — this file is the version-controlled source of truth going
forward; update it as decisions evolve.

## Quick facts

| | |
|---|---|
| Base | Fedora Linux, latest stable release (currently Fedora 44) |
| Architecture | x86_64 only |
| Desktop | GNOME Shell |
| Installer | Anaconda |
| System model | Traditional, package-based (dnf/RPM) — not atomic/immutable |
| Filesystem | Btrfs with automatic pre-update snapshots |
| License | MIT/Apache-2.0 (scripts/configs) + CC-BY-4.0 (branding art) |

## Accessibility — north star

> "Any user, whether sighted or not, should be able to access and install the system
> from the very first step. This means everything on the system — Orca, speech, the
> underlying audio stack — has to be good to go regardless of the hardware it's
> running on."

- **Live session & installer:** Orca is launchable immediately from the boot menu,
  before Anaconda even starts, and stays available identically through install and
  first-run setup.
- **Installer choice:** Anaconda was chosen over the more easily-reskinned Calamares
  specifically because it has a proven, years-tested screen-reader workflow —
  Calamares does not.
- **High-contrast theme:** ships as an official, first-class alternate look, not a
  generic fallback.
- **First-run setup:** text size and display scaling are surfaced prominently, not
  buried in Settings.
- **Every custom visual** — wallpaper, theme colors, boot splash, icons — gets
  checked against WCAG contrast guidelines before being locked in.

## Identity & base

| Decision | Choice | Why it matters |
|---|---|---|
| Purpose | General-purpose desktop OS | Daily-driver priorities: stability, broad out-of-box app coverage, approachability for switchers. |
| Base distro | Fedora Linux, latest stable release | Strong upstream GNOME integration, respected accessibility investment from Red Hat, permissive remix/trademark policy. |
| Architecture | x86_64 only | Covers the overwhelming majority of real desktop/laptop hardware without doubling build & QA effort. |
| Desktop environment | GNOME Shell | Best current combination of visual coherence and accessibility (Orca, AT-SPI) maturity. |
| Working style | Claude drives technical execution; Elliott makes creative/identity calls | First distro-building project — decisions get made together, execution stays low-friction. |

## Visual identity

Brand assets were left to Claude's judgment. First concept pass: a cool teal/blue
palette (calm, professional, easiest to keep WCAG-contrast-safe), a two-plane mark
suggesting a shift in perspective, and an aspirational, alphabetical codename scheme.

**Palette**

| Token | Hex | Use |
|---|---|---|
| Teal (primary) | `#1B8A90` | Primary accent |
| Deep Blue | `#2B5D86` | Secondary accent |
| Ink | `#12262B` | Text (light mode) |
| Paper | `#F5F9FA` | Background (light mode) |
| Flag / semantic | `#A4501F` | "Needs attention" markers only, never used as brand accent |

| Decision | Choice | Why it matters |
|---|---|---|
| Wallpaper | Rotating set, paired light/dark variants; proposed style: abstract geometric/gradient | Structure (rotating, paired) was decided directly; the abstract-geometric visual style is Claude's proposal — flag if you'd rather go photographic or minimalist. |
| Wordmark / mark | Geometric sans wordmark + two overlapping "shifted plane" shapes | Literalizes "paradigm shift" without cliché; simple enough to stay legible at favicon size and in high-contrast mode. |
| Versioning | Independent version number + codename | Decoupled from the underlying Fedora version, shown in fine print only. |
| Codename scheme | Abstract/aspirational words, alphabetical across releases | v1.0 proposed as **"Aurora"**; v2.0 would be a B-word, and so on. |

## Default applications

| Decision | Choice | Why it matters |
|---|---|---|
| App philosophy | Mix GNOME-native + popular third-party apps | GNOME-native apps stay the fallback for consistency/accessibility; third-party swaps happen only where they add real capability, checked for a11y polish first. |
| Browser | Firefox | Fedora Workstation's actual default; mature screen-reader support, no telemetry baggage. |
| Office suite | LibreOffice, full suite preinstalled | Matches stock Fedora Workstation expectations for a general-purpose desktop. |
| Media player | VLC (default handler) + GNOME Videos (Totem), both installed | VLC's format coverage handles the "just works" bar; Totem stays available for the native look. |
| Email client | None preinstalled | Most general users default to webmail today; keeps the base image leaner. |
| Code/text editor | GNOME Text Editor only | Kept minimal; VS Code and others are a one-click Software Center install, not a default. |
| Codecs & drivers | RPM Fusion + proprietary codecs + NVIDIA driver detection, bundled by default | Video/audio/gaming/GPU acceleration "just work" — the standard approach used by Fedora remixes like Nobara and Ultramarine. |

## Desktop experience

| Decision | Choice | Why it matters |
|---|---|---|
| Desktop layout | Persistent dock (macOS-like) | More familiar to switchers than vanilla GNOME's Activities-only workflow; must ship via an Orca-compatible, well-maintained dock extension (Dash-to-Dock family), accessibility-tested before lock-in. |
| Theming | Teal/blue palette applied through GNOME Shell + GTK + icon theme; high-contrast variant included | Keeps the branded look and the accessible fallback as equally first-class options. |

## Installer & system architecture

| Decision | Choice | Why it matters |
|---|---|---|
| Installer | Anaconda | Only proven option for unattended, screen-reader-driven installs; rebranded via Fedora's supported hooks (logo, welcome banner, `os-release` strings) rather than a fork. |
| System model | Traditional, package-based (dnf/RPM) | Simplest to build, customize, and maintain for a first distro project — not an atomic/immutable (OSTree) system. |
| Disk encryption | LUKS offered, unchecked by default | Clearly available but opt-in, so a forgotten passphrase can't lock out a first-time or accessibility-dependent user. |
| Filesystem | Btrfs with automatic pre-update snapshots | A real rollback safety net if an update breaks something — matches current Fedora Workstation default. |

## Governance & release

| Decision | Choice | Why it matters |
|---|---|---|
| Scope/audience | Public release | Warrants real trademark and licensing diligence, not just personal-use good sense. |
| Telemetry | None by default | Nothing phones home; matches a privacy-respecting general-audience distro. |
| Update cadence | Undecided — leaning ~12-month major cycle (skipping one Fedora release per cycle) | Deliberately deferred until after v1 ships; build pipeline is scripted regardless so a rebase is low-effort whenever it happens. |
| Trademark/legal | Claude handles Fedora Remix compliance end-to-end | No Fedora logo, clear "unofficial community remix" disclosure, license compliance for bundled packages — flagged to you only where genuine judgment calls arise. |
| Openness | Fully open, public repo | Kickstart files, build scripts, and branding source all public — standard practice for community Fedora remixes, builds contributor trust. |
| Distribution | Dedicated website + GitHub Releases | Website as the public face, GitHub Releases as the actual file host behind it. |
| Licensing | MIT/Apache-2.0 (scripts & configs) + Creative Commons (wallpapers/art) | Standard, maximizes reuse and trust. Note: the ParadigmOS name/wordmark can still be reserved as a mark even under an open art license — worth a deliberate call later. |

## Open items

- **Needs your input:** GitHub username/org + repo name; domain name (e.g.
  `paradigmos.org`).
- **Proposed, awaiting your confirmation:** wallpaper visual style (abstract
  geometric) and the two-plane wordmark concept.
- **Deliberately deferred:** exact update-cadence commitment — revisit after v1 ships.

## Build environment (set up during planning)

- WSL2 (Ubuntu 24.04) was already present on the build machine — no Windows feature
  changes were needed.
- Docker Engine installed directly inside that WSL2 instance (not Docker Desktop),
  enabled via systemd, current user added to the `docker` group.
- Verified by pulling and running the official `fedora:latest` container
  (resolves to Fedora 44, the current stable release).
- The actual ISO build (kickstart + `livemedia-creator`/`lorax`) will run inside a
  Fedora container so the Fedora-specific tooling doesn't need to be cross-installed
  on the Ubuntu WSL base.
