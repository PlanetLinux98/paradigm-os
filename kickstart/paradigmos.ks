# ParadigmOS 1.0 "Aurora" — live/install image kickstart
# Target: Fedora 44, x86_64, GNOME Workstation base.
# Built with livemedia-creator --no-virt inside a fedora:44 container
# (see build/build-iso.sh). Self-contained on purpose: no %include, so no
# ksflatten step is needed.
#
# STATUS: first draft — expect iteration during the first real build.
# TODO markers below are the known-open items.

lang en_US.UTF-8
keyboard us
timezone America/New_York
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
rootpw --lock --iscrypted locked
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

# ---- Branding: wallpapers ----
# Interim: pull current drafts from the public repo at build time.
# TODO(packaging): replace with a paradigmos-backgrounds RPM before v1.
mkdir -p /usr/share/backgrounds/paradigmos
for f in aurora-1-light.svg aurora-1-dark.svg; do
  curl -sfL "https://raw.githubusercontent.com/PlanetLinux98/paradigm-os/main/branding/wallpapers/$f" \
    -o "/usr/share/backgrounds/paradigmos/$f" || echo "WARN: wallpaper $f not fetched"
done

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
