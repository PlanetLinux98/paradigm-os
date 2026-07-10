# kickstart/

Fedora kickstart (`.ks`) files defining ParadigmOS's package set, repositories
(including RPM Fusion), live-image configuration, and post-install branding
hooks (`os-release`, wallpapers, dconf desktop defaults, VLC file associations).

- `paradigmos.ks` — the live/install image definition (first draft). Targets
  Fedora 44, GNOME Workstation base. Self-contained (no `%include`), so it can
  be fed straight to `livemedia-creator` — see `build/build-iso.sh`.

Open items before the first ISO is considered "real" are tracked as `TODO(...)`
markers inside the kickstart itself.
