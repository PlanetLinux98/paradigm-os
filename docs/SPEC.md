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
- **How (decided 2026-07-10):** every ISO's boot menu — BIOS and UEFI — carries a
  dedicated entry, **"Start ParadigmOS 1.0 with screen reader (press S)"**, placed
  right below the default entry. Pressing `S` boots it directly: no arrow keys, no
  sight needed (pressing `↓` then `Enter` from the default works too). The entry
  adds the kernel argument `paradigmos.a11y=screenreader`; a boot-time service
  flips GNOME's screen-reader default on system-wide before GDM starts, so Orca is
  already talking when the live session appears. Installing from that session
  carries the setting onto the installed system (via an Anaconda post-script), so
  the first boot and `gnome-initial-setup` speak as well. In any session,
  `Super+Alt+S` still toggles Orca manually.
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

The cool teal/blue palette is confirmed. The mark is decided: **"Shifted tile"**
(`branding/icons/paradigmos-mark.svg`) — a 3×3 grid of rounded tiles where the
top-right tile turns teal, rotates, and escapes the grid (the paradigm shift).
Per Elliott's refinement idea, the five tiles of column 1 + top two of column 2
sit darker (#1F4A6E), tracing a subtle letter **P**; the three non-P grid tiles
sit lighter (#4A8ABD). Settled 2026-07-10 after two rounds: Elliott kept the
original P shade and only lightened the grid tiles. (An earlier
literal letter-P concept and two alternates — aurora-ring, horizon-shift — were
explored and rejected; they survive in git history.)

The wallpapers use a sweeping, Vista-like gradient "aurora" direction
(confirmed). Grounds must avoid pure whites and pure blacks and carry real
colour, blue included — per Elliott's feedback on the first two passes.
**Set 1 (`aurora-1`, light + dark) approved by Elliott 2026-07-10** as the
first of the rotating set; he wants at least three or four more sets in
varying designs that stay within these style rules. Proposals live in
`branding/wallpapers/` as they're drafted.

**Palette**

| Token | Hex | Use |
|---|---|---|
| Teal (primary) | `#2190A4` | Primary accent — deliberately identical to GNOME's built-in `teal` accent colour (Elliott, 2026-07-10), so the supported accent system matches the brand exactly |
| Deep Blue | `#2B5D86` | Secondary accent |
| Deep Blue (shade) | `#1F4A6E` | The mark's P-tiles |
| Deep Blue (light shade) | `#4A8ABD` | The mark's non-P grid tiles |
| Ink | `#12262B` | Text (light mode) |
| Paper | `#F5F9FA` | Background (light mode) |
| Flag / semantic | `#A4501F` | "Needs attention" markers only, never used as brand accent |

| Decision | Choice | Why it matters |
|---|---|---|
| Wallpaper | Rotating set, paired light/dark variants; sweeping gradient "aurora" style, saturated grounds (no pure white/black) | Set 1 approved (2026-07-10); 3–4 more sets in varying designs to follow, then Elliott picks the rotation. |
| Wordmark / mark | "Shifted tile" — three-tone 3×3 grid: dark navy P-tiles (#1F4A6E), lighter grid tiles (#4A8ABD), escaping teal tile (#2190A4) | Elliott picked the concept and settled the tones over two rounds (2026-07-10): P-tiles keep their original shade, grid tiles go lighter, so the P differentiates without darkening. |
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
| Accent colour | GNOME's built-in `teal` accent (`accent-color='teal'` dconf default), with the brand teal aligned to it (#2190A4) | Decided 2026-07-10. Uses the supported libadwaita accent system — update-proof, high-contrast-safe, user-changeable — instead of fragile CSS overrides; the palette alignment makes it exact rather than approximate. |

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
| Distribution | GitHub Releases at `github.com/PlanetLinux98/paradigm-os`; dedicated website deferred | Repo name confirmed by Elliott (2026-07-10); a website becomes the public face closer to the v1 release. |
| Licensing | MIT/Apache-2.0 (scripts & configs) + Creative Commons (wallpapers/art) | Standard, maximizes reuse and trust. Note: the ParadigmOS name/wordmark can still be reserved as a mark even under an open art license — worth a deliberate call later. |

## Open items

- **Awaiting Elliott's reaction:** the darker-P-tile shading on the mark, and
  the third wallpaper colour pass (light draft 3, dark draft 2).
- **Deliberately deferred:** exact update-cadence commitment (revisit after v1
  ships; leaning ~12-month major cycle) and the website/domain (revisit
  approaching v1).

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
