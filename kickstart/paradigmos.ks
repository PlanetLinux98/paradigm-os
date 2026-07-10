# ParadigmOS 1.0 "Aurora" — live/install image kickstart
# Target: Fedora 44, x86_64, GNOME Workstation base.
# Built with livemedia-creator --no-virt inside a fedora:44 container
# (see build/build-iso.sh). Self-contained on purpose: no %include, so no
# ksflatten step is needed.
#
# STATUS: first draft — expect iteration during the first real build.
# TODO markers below are the known-open items.

# Canadian English default (Elliott's call, 2026-07-10): identity statement
# only — Anaconda still asks every user for language on its first screen.
# Keyboard stays US layout (standard for Canadian English hardware).
lang en_CA.UTF-8
keyboard us
timezone America/Toronto
selinux --enforcing
firewall --enabled --service=mdns
xconfig --startxonboot
zerombr
clearpart --all
# Live-image rootfs (ext4 is the convention for the live squashfs source;
# installed systems get Btrfs via Anaconda's defaults). Sized generously for
# the Workstation + LibreOffice + multimedia package set.
part / --size 16384 --fstype ext4
services --enabled=NetworkManager,ModemManager --disabled=sshd
network --bootproto=dhcp --device=link --activate
# Locked root account, no password set. (The older idiom
# `--iscrypted locked` fails validation in current anaconda:
# "Unable to set password for new user: status=1".)
rootpw --lock
shutdown

# --- Repositories -----------------------------------------------------------
# Fedora proper + updates, plus RPM Fusion (free and nonfree) per the spec:
# codecs and NVIDIA driver availability out of the box.
# livemedia-creator requires the primary install source as a `url` command;
# additional `repo` lines are only allowed alongside it.
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f44&arch=x86_64
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-44&arch=x86_64
repo --name=rpmfusion-free-updates --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-44&arch=x86_64
repo --name=rpmfusion-nonfree --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-44&arch=x86_64
repo --name=rpmfusion-nonfree-updates --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-44&arch=x86_64

# --- Packages ---------------------------------------------------------------
%packages
@^workstation-product-environment

# Live-image plumbing and the installer itself
livesys-scripts
anaconda
anaconda-live
@anaconda-tools

# Live-boot essentials (livemedia-creator aborts without dracut-live; the
# rest are the standard Fedora live-media boot stack pulled from the built
# rootfs by the lorax live templates)
dracut-live
grub2-efi-x64
grub2-efi-x64-cdboot
shim-x64
syslinux
isomd5sum

# Per spec: office suite preinstalled (no longer in stock Workstation default)
libreoffice

# Per spec: VLC as default media handler alongside GNOME Videos.
# vlc lives in Fedora proper now; the freeworld plugins come from RPM Fusion.
vlc
vlc-plugins-freeworld

# Full multimedia coverage from RPM Fusion
ffmpeg
gstreamer1-plugins-ugly
gstreamer1-plugins-bad-freeworld
gstreamer1-libav

# Desktop layout: persistent dock
gnome-shell-extension-dash-to-dock

# Accessibility stack — must work in the live session out of the box.
# orca ships with Workstation; make it explicit anyway, plus speech + braille.
orca
speech-dispatcher
espeak-ng
brltty

# Fedora Remix trademark compliance: generic logos instead of Fedora's
generic-logos
-fedora-logos

# Keep the image lean per spec (no email client, no extra editors)
-rhythmbox

# TODO(nvidia): decide the akmod-nvidia strategy. Preinstalling it on the
# live ISO blacklists nouveau on all hardware; remixes usually ship a
# first-boot detection service instead. Deferred to the build/test phase.
%end

# --- System configuration ---------------------------------------------------
%post

# Live session setup (livesys-scripts)
systemctl enable livesys.service livesys-late.service
sed -i 's/^livesys_session=.*/livesys_session="gnome"/' /etc/sysconfig/livesys

# ---- Branding: os-release ----
# Remix-compliant rebrand: ParadigmOS identity, with CPE and bug URLs left
# pointing at nothing Fedora-branded. VARIANT records the Fedora base.
cat > /usr/lib/os-release << 'EOF'
NAME="ParadigmOS"
VERSION="1.0 (Aurora)"
ID=paradigmos
ID_LIKE=fedora
VERSION_ID=1.0
VERSION_CODENAME=aurora
PLATFORM_ID="platform:f44"
PRETTY_NAME="ParadigmOS 1.0 (Aurora)"
ANSI_COLOR="0;36"
LOGO=paradigmos-logo
HOME_URL="https://github.com/PlanetLinux98/paradigm-os"
BUG_REPORT_URL="https://github.com/PlanetLinux98/paradigm-os/issues"
VARIANT="Desktop (Fedora 44 Remix)"
VARIANT_ID=desktop
EOF
ln -sf ../usr/lib/os-release /etc/os-release

# ---- Branding: wallpapers & logo ----
# Assets embedded directly so the build is hermetic — no network fetch, no
# risk of building against a stale GitHub main. Keep in sync with branding/
# in the repo. TODO(packaging): paradigmos-{backgrounds,logos} RPMs by v1.
mkdir -p /usr/share/backgrounds/paradigmos
cat > /usr/share/backgrounds/paradigmos/aurora-1-light.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Aurora 1 (light variant)</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#E4F0F2"/>
      <stop offset="0.5" stop-color="#D2E6EA"/>
      <stop offset="1" stop-color="#B9D8DF"/>
    </linearGradient>
    <linearGradient id="band1" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#1B8A90" stop-opacity="0.10"/>
      <stop offset="0.5" stop-color="#1B8A90" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0.16"/>
    </linearGradient>
    <linearGradient id="band2" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.10"/>
      <stop offset="0.6" stop-color="#2B5D86" stop-opacity="0.32"/>
      <stop offset="1" stop-color="#1B8A90" stop-opacity="0.14"/>
    </linearGradient>
    <linearGradient id="ribbon" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#1B8A90" stop-opacity="0"/>
      <stop offset="0.5" stop-color="#17797E" stop-opacity="0.75"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.78" cy="0.72" r="0.55">
      <stop offset="0" stop-color="#1B8A90" stop-opacity="0.24"/>
      <stop offset="1" stop-color="#1B8A90" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="washTeal" cx="0.12" cy="0.08" r="0.6">
      <stop offset="0" stop-color="#1B8A90" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#1B8A90" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="washBlue" cx="0.9" cy="0.15" r="0.65">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="14"/></filter>
    <filter id="soft2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="5"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#washTeal)"/>
  <rect width="1920" height="1080" fill="url(#washBlue)"/>
  <rect width="1920" height="1080" fill="url(#glow)"/>
  <path d="M0,260 C620,150 1260,330 1920,190 L1920,0 L0,0 Z" fill="url(#band2)" opacity="0.6" filter="url(#soft)"/>
  <path d="M0,780 C420,630 900,910 1380,720 C1630,620 1790,660 1920,590 L1920,1080 L0,1080 Z" fill="url(#band1)" filter="url(#soft)"/>
  <path d="M0,920 C520,770 1040,1010 1500,850 C1700,780 1830,800 1920,750 L1920,1080 L0,1080 Z" fill="url(#band2)" filter="url(#soft)"/>
  <path d="M-60,830 C480,660 980,890 1410,700 C1660,592 1830,640 1980,555" fill="none" stroke="url(#ribbon)" stroke-width="6" filter="url(#soft2)"/>
  <path d="M-60,890 C500,740 1020,960 1450,790 C1690,698 1840,724 1980,655" fill="none" stroke="url(#ribbon)" stroke-width="3" opacity="0.8" filter="url(#soft2)"/>
</svg>
EOF
cat > /usr/share/backgrounds/paradigmos/aurora-1-dark.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Aurora 1 (dark variant)</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#122834"/>
      <stop offset="0.5" stop-color="#17374A"/>
      <stop offset="1" stop-color="#1C4A5C"/>
    </linearGradient>
    <linearGradient id="band1" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#1B8A90" stop-opacity="0.08"/>
      <stop offset="0.5" stop-color="#2FA3A9" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0.14"/>
    </linearGradient>
    <linearGradient id="band2" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.10"/>
      <stop offset="0.6" stop-color="#5F9CCF" stop-opacity="0.32"/>
      <stop offset="1" stop-color="#1B8A90" stop-opacity="0.12"/>
    </linearGradient>
    <linearGradient id="ribbon" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2FA3A9" stop-opacity="0"/>
      <stop offset="0.5" stop-color="#4FC7CD" stop-opacity="0.9"/>
      <stop offset="1" stop-color="#5F9CCF" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.78" cy="0.72" r="0.55">
      <stop offset="0" stop-color="#1B8A90" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#1B8A90" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="washBlue" cx="0.12" cy="0.1" r="0.65">
      <stop offset="0" stop-color="#5F9CCF" stop-opacity="0.20"/>
      <stop offset="1" stop-color="#5F9CCF" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="14"/></filter>
    <filter id="soft2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="5"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#washBlue)"/>
  <rect width="1920" height="1080" fill="url(#glow)"/>
  <path d="M0,260 C620,150 1260,330 1920,190 L1920,0 L0,0 Z" fill="url(#band2)" opacity="0.5" filter="url(#soft)"/>
  <path d="M0,780 C420,630 900,910 1380,720 C1630,620 1790,660 1920,590 L1920,1080 L0,1080 Z" fill="url(#band1)" filter="url(#soft)"/>
  <path d="M0,920 C520,770 1040,1010 1500,850 C1700,780 1830,800 1920,750 L1920,1080 L0,1080 Z" fill="url(#band2)" filter="url(#soft)"/>
  <path d="M-60,830 C480,660 980,890 1410,700 C1660,592 1830,640 1980,555" fill="none" stroke="url(#ribbon)" stroke-width="6" filter="url(#soft2)"/>
  <path d="M-60,890 C500,740 1020,960 1450,790 C1690,698 1840,724 1980,655" fill="none" stroke="url(#ribbon)" stroke-width="3" opacity="0.75" filter="url(#soft2)"/>
</svg>
EOF

# The shifted-tile mark, installed under our own icon name (matching
# os-release LOGO=paradigmos-logo) and also as fedora-logo-icon — the name
# anaconda's desktop entry references; without it the installer shows
# anaconda's hot-dog placeholder icon.
mkdir -p /usr/share/icons/hicolor/scalable/apps
cat > /usr/share/icons/hicolor/scalable/apps/paradigmos-logo.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120">
  <title>ParadigmOS mark — "Shifted tile"</title>
  <g fill="#1F4A6E">
    <rect x="16" y="16" width="24" height="24" rx="6"/>
    <rect x="48" y="16" width="24" height="24" rx="6"/>
    <rect x="16" y="48" width="24" height="24" rx="6"/>
    <rect x="48" y="48" width="24" height="24" rx="6"/>
    <rect x="16" y="80" width="24" height="24" rx="6"/>
  </g>
  <g fill="#2B5D86">
    <rect x="80" y="48" width="24" height="24" rx="6"/>
    <rect x="48" y="80" width="24" height="24" rx="6"/>
    <rect x="80" y="80" width="24" height="24" rx="6"/>
  </g>
  <rect x="80" y="16" width="24" height="24" rx="6" fill="#1B8A90"
        transform="translate(9,-7) rotate(14 92 28)"/>
</svg>
EOF
cp /usr/share/icons/hicolor/scalable/apps/paradigmos-logo.svg \
   /usr/share/icons/hicolor/scalable/apps/fedora-logo-icon.svg
gtk-update-icon-cache -f /usr/share/icons/hicolor || true

mkdir -p /usr/share/gnome-background-properties
cat > /usr/share/gnome-background-properties/paradigmos.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>Aurora</name>
    <filename>/usr/share/backgrounds/paradigmos/aurora-1-light.svg</filename>
    <filename-dark>/usr/share/backgrounds/paradigmos/aurora-1-dark.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#1B8A90</pcolor>
    <scolor>#2B5D86</scolor>
  </wallpaper>
</wallpapers>
EOF

# ---- Desktop defaults (dconf) ----
# System defaults only apply if a profile chains the system database —
# Fedora ships no such profile, so without this file every key below is
# silently ignored (confirmed by the first boot test: plain blue desktop).
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00-paradigmos << 'EOF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/paradigmos/aurora-1-light.svg'
picture-uri-dark='file:///usr/share/backgrounds/paradigmos/aurora-1-dark.svg'
picture-options='zoom'

[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com']

[org/gnome/desktop/interface]
# Accessibility: keep the universal-access menu always visible in the top bar
toolkit-accessibility=true
EOF
dconf update

# ---- Default file associations: VLC handles media ----
mkdir -p /usr/share/applications
cat > /usr/share/applications/paradigmos-mimeapps.list << 'EOF'
# Merged into the system default via /usr/share/applications/mimeapps.list
EOF
# Append VLC as default handler for common a/v types
cat >> /usr/share/applications/mimeapps.list << 'EOF'
[Default Applications]
video/mp4=vlc.desktop
video/x-matroska=vlc.desktop
video/webm=vlc.desktop
video/quicktime=vlc.desktop
audio/mpeg=vlc.desktop
audio/flac=vlc.desktop
audio/x-wav=vlc.desktop
audio/ogg=vlc.desktop
EOF

# ---- Telemetry: none ----
# Nothing to disable in stock Fedora 44 (its metrics are opt-in), recorded
# here as an explicit spec commitment.

# TODO(anaconda-branding): welcome banner + installer product name via the
#   supported hooks; verify the Orca boot-menu entry in the lorax templates.
# TODO(theme): branded GNOME theme + first-class high-contrast variant.
# TODO(plymouth): ParadigmOS boot splash.
# TODO(snapshots): preinstall and configure btrfs snapshot tooling (snapper
#   or btrfs-assistant) for automatic pre-update snapshots per spec.

%end
