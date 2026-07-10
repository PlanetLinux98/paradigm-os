# ParadigmOS

A Fedora-based, GNOME desktop Linux distribution built accessibility-first — from
the boot menu to daily use. General-purpose daily-driver, not a niche/developer
spin.

**Status:** early planning / pre-build. See [`docs/SPEC.md`](docs/SPEC.md) for the
full project specification (base distro, branding, accessibility commitments,
default apps, installer, licensing, and release plan).

## Accessibility

ParadigmOS is built around a hard requirement: any user, sighted or not, must be
able to install and use the system from the very first step. Orca is reachable
straight from the boot menu, before the installer even starts, and stays available
identically through install and first-run setup. See the SPEC for the full set of
accessibility commitments.

## Repository layout

- `docs/` — project specification and other planning documents.
- `kickstart/` — Fedora kickstart (`.ks`) files defining package sets and system
  configuration for the ISO build.
- `branding/` — wallpapers, icons, GNOME Shell/GTK theme, boot splash, and other
  visual identity assets.
- `build/` — build scripts and the Fedora container/tooling used to produce the
  ISO.

## Build environment

The ISO is built inside a Fedora container (using `livemedia-creator`/`lorax`
against a kickstart file) run from Docker inside WSL2 on the maintainer's machine.
See `build/` for the container definition and build scripts as they're added.

## License

- Build scripts and kickstart configs: MIT (see `LICENSE`).
- Branding assets (wallpapers, icons, theme): CC-BY-4.0 (see `LICENSE-ASSETS`). The
  ParadigmOS name and wordmark are reserved as project marks even where the
  underlying art file is openly licensed.

## Fedora Remix disclosure

ParadigmOS is an independent, community-built remix of Fedora Linux. It is not
produced by, affiliated with, or endorsed by the Fedora Project or Red Hat, Inc.
"Fedora" and the Fedora logo are trademarks of Red Hat, Inc.; no Fedora trademarks
are used in ParadigmOS's own branding.
