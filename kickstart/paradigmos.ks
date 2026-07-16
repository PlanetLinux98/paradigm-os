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
# @BUILDID@/@BUILDINFO@ are filled by build/build-iso.sh (build number from
# build/BUILD_NUMBER + git hash + date) into a stamped copy at build time —
# this repo copy keeps the placeholders. BUILD_ID surfaces in
# `cat /etc/os-release` and as the "OS Build" row in GNOME Settings > About.
cat > /usr/lib/os-release << 'EOF'
NAME="ParadigmOS"
VERSION="1.0 (Aurora)"
ID=paradigmos
ID_LIKE=fedora
VERSION_ID=1.0
VERSION_CODENAME=aurora
BUILD_ID="@BUILDID@"
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

# One human-readable line for support conversations: which build is this?
echo "@BUILDINFO@" > /etc/paradigmos-release

# ---- Anaconda profile: keep the installer working after the rebrand ----
# Anaconda picks its "profile" by matching the RUNNING system's os-release
# ID/VARIANT_ID exactly against /etc/anaconda/profile.d/ (ID_LIKE is NOT
# consulted). Our ID=paradigmos matched nothing, so no profile loaded and
# efi_dir stayed at the base default "default": UEFI installs from build 6
# died in gen_grub_cfgstub trying to write /boot/efi/EFI/default/grub.cfg
# into a directory that doesn't exist (2026-07-11). Basing on
# fedora-workstation (which chains to fedora) restores efi_dir=fedora —
# the signed shim's baked-in path, never change it — plus Btrfs-by-default
# partitioning, menu auto-hide, and the Workstation installer stylesheet.
mkdir -p /etc/anaconda/profile.d
cat > /etc/anaconda/profile.d/paradigmos.conf << 'EOF'
[Profile]
# Define the profile.
profile_id = paradigmos
base_profile = fedora-workstation

[Profile Detection]
# Match os-release values.
os_id = paradigmos
EOF

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
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.10"/>
      <stop offset="0.5" stop-color="#2190A4" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0.16"/>
    </linearGradient>
    <linearGradient id="band2" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.10"/>
      <stop offset="0.6" stop-color="#2B5D86" stop-opacity="0.32"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0.14"/>
    </linearGradient>
    <linearGradient id="ribbon" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0"/>
      <stop offset="0.5" stop-color="#176E7E" stop-opacity="0.75"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.78" cy="0.72" r="0.55">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.24"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="washTeal" cx="0.12" cy="0.08" r="0.6">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
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
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.08"/>
      <stop offset="0.5" stop-color="#2F97A9" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0.14"/>
    </linearGradient>
    <linearGradient id="band2" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.10"/>
      <stop offset="0.6" stop-color="#5F9CCF" stop-opacity="0.32"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0.12"/>
    </linearGradient>
    <linearGradient id="ribbon" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#2F97A9" stop-opacity="0"/>
      <stop offset="0.5" stop-color="#4FBACD" stop-opacity="0.9"/>
      <stop offset="1" stop-color="#5F9CCF" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.78" cy="0.72" r="0.55">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
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

# Sets 2-5 (shift, headland, ripple, curtain), approved by Elliott
# 2026-07-10 after three revision rounds. Copies of branding/wallpapers/.

cat > /usr/share/backgrounds/paradigmos/shift-light.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Shift (light variant, rev 3): a diagonal cascade of tiles rising across the canvas toward one teal escapee</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#C6E7E6"/>
      <stop offset="0.55" stop-color="#B0DBDD"/>
      <stop offset="1" stop-color="#9CCED6"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.85" cy="0.42" r="0.55">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.22"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="washBlue" cx="0.08" cy="0.1" r="0.7">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.14"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="3"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#washBlue)"/>
  <rect width="1920" height="1080" fill="url(#glow)"/>
  <g fill="#4A8ABD" filter="url(#soft)">
    <rect x="120" y="140" width="84" height="84" rx="20" opacity="0.08"/>
    <rect x="380" y="260" width="84" height="84" rx="20" opacity="0.10"/>
    <rect x="120" y="890" width="84" height="84" rx="20" opacity="0.14"/>
    <rect x="250" y="1010" width="84" height="84" rx="20" opacity="0.12"/>
    <rect x="250" y="760" width="84" height="84" rx="20" opacity="0.18"/>
    <rect x="380" y="890" width="96" height="96" rx="22" opacity="0.20"/>
    <rect x="510" y="1010" width="96" height="96" rx="22" opacity="0.16"/>
    <rect x="510" y="760" width="96" height="96" rx="22" opacity="0.22"/>
    <rect x="640" y="890" width="96" height="96" rx="22" opacity="0.24"/>
    <rect x="770" y="630" width="96" height="96" rx="22" opacity="0.20"/>
    <rect x="770" y="1010" width="96" height="96" rx="22" opacity="0.18"/>
    <rect x="900" y="760" width="96" height="96" rx="22" opacity="0.26"/>
    <rect x="1030" y="890" width="96" height="96" rx="22" opacity="0.28"/>
    <rect x="1030" y="630" width="96" height="96" rx="22" opacity="0.22"/>
    <rect x="1160" y="760" width="96" height="96" rx="22" opacity="0.30"/>
    <rect x="1290" y="500" width="96" height="96" rx="22" opacity="0.24"/>
    <rect x="1290" y="890" width="96" height="96" rx="22" opacity="0.26"/>
    <rect x="1420" y="630" width="96" height="96" rx="22" opacity="0.32"/>
    <rect x="1550" y="760" width="104" height="104" rx="24" opacity="0.30"/>
    <rect x="1680" y="890" width="96" height="96" rx="22" opacity="0.26"/>
    <rect x="1810" y="1010" width="96" height="96" rx="22" opacity="0.18"/>
  </g>
  <g fill="#1A3F5F" filter="url(#soft)">
    <rect x="1160" y="500" width="96" height="96" rx="22" opacity="0.34"/>
    <rect x="1420" y="890" width="96" height="96" rx="22" opacity="0.38"/>
    <rect x="1550" y="500" width="96" height="96" rx="22" opacity="0.34"/>
    <rect x="1680" y="630" width="104" height="104" rx="24" opacity="0.40"/>
    <rect x="1810" y="760" width="96" height="96" rx="22" opacity="0.34"/>
  </g>
  <rect x="1660" y="360" width="112" height="112" rx="26" fill="#2190A4" opacity="0.9"
        transform="rotate(14 1716 416)"/>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/shift-dark.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Shift (dark variant, rev 3): a glowing diagonal cascade of tiles rising toward one bright teal escapee</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#0F2233"/>
      <stop offset="0.55" stop-color="#153048"/>
      <stop offset="1" stop-color="#1A3F5F"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.85" cy="0.42" r="0.55">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.36"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="washBlue" cx="0.08" cy="0.1" r="0.7">
      <stop offset="0" stop-color="#4A8ABD" stop-opacity="0.16"/>
      <stop offset="1" stop-color="#4A8ABD" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="3"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#washBlue)"/>
  <rect width="1920" height="1080" fill="url(#glow)"/>
  <g fill="#4A8ABD" filter="url(#soft)">
    <rect x="120" y="140" width="84" height="84" rx="20" opacity="0.10"/>
    <rect x="380" y="260" width="84" height="84" rx="20" opacity="0.12"/>
    <rect x="120" y="890" width="84" height="84" rx="20" opacity="0.16"/>
    <rect x="250" y="1010" width="84" height="84" rx="20" opacity="0.14"/>
    <rect x="250" y="760" width="84" height="84" rx="20" opacity="0.20"/>
    <rect x="380" y="890" width="96" height="96" rx="22" opacity="0.22"/>
    <rect x="510" y="1010" width="96" height="96" rx="22" opacity="0.18"/>
    <rect x="510" y="760" width="96" height="96" rx="22" opacity="0.24"/>
    <rect x="640" y="890" width="96" height="96" rx="22" opacity="0.26"/>
    <rect x="770" y="630" width="96" height="96" rx="22" opacity="0.22"/>
    <rect x="770" y="1010" width="96" height="96" rx="22" opacity="0.20"/>
    <rect x="900" y="760" width="96" height="96" rx="22" opacity="0.28"/>
    <rect x="1030" y="890" width="96" height="96" rx="22" opacity="0.30"/>
    <rect x="1030" y="630" width="96" height="96" rx="22" opacity="0.24"/>
    <rect x="1160" y="760" width="96" height="96" rx="22" opacity="0.32"/>
    <rect x="1290" y="500" width="96" height="96" rx="22" opacity="0.26"/>
    <rect x="1290" y="890" width="96" height="96" rx="22" opacity="0.28"/>
    <rect x="1420" y="630" width="96" height="96" rx="22" opacity="0.34"/>
    <rect x="1550" y="760" width="104" height="104" rx="24" opacity="0.32"/>
    <rect x="1680" y="890" width="96" height="96" rx="22" opacity="0.28"/>
    <rect x="1810" y="1010" width="96" height="96" rx="22" opacity="0.20"/>
  </g>
  <g fill="#7FB2DD" filter="url(#soft)">
    <rect x="1160" y="500" width="96" height="96" rx="22" opacity="0.30"/>
    <rect x="1420" y="890" width="96" height="96" rx="22" opacity="0.34"/>
    <rect x="1550" y="500" width="96" height="96" rx="22" opacity="0.30"/>
    <rect x="1680" y="630" width="104" height="104" rx="24" opacity="0.36"/>
    <rect x="1810" y="760" width="96" height="96" rx="22" opacity="0.30"/>
  </g>
  <rect x="1660" y="360" width="112" height="112" rx="26" fill="#4FBACD" opacity="0.92"
        transform="rotate(14 1716 416)"/>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/headland-light.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Headland (light variant, rev 3): five sweeping ridge layers filling most of the frame</title>
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#D9EDF0"/>
      <stop offset="0.6" stop-color="#C2E0E7"/>
      <stop offset="1" stop-color="#ADD3DF"/>
    </linearGradient>
    <radialGradient id="sun" cx="0.68" cy="0.3" r="0.5">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.28"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="h0" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4A8ABD" stop-opacity="0.35"/>
      <stop offset="1" stop-color="#4A8ABD" stop-opacity="0.08"/>
    </linearGradient>
    <linearGradient id="h1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.50"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0.12"/>
    </linearGradient>
    <linearGradient id="h2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#176E7E" stop-opacity="0.60"/>
      <stop offset="1" stop-color="#176E7E" stop-opacity="0.18"/>
    </linearGradient>
    <linearGradient id="h3" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.66"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0.26"/>
    </linearGradient>
    <linearGradient id="h4" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1A3F5F" stop-opacity="0.78"/>
      <stop offset="1" stop-color="#1A3F5F" stop-opacity="0.34"/>
    </linearGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="18"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#sky)"/>
  <rect width="1920" height="1080" fill="url(#sun)"/>
  <path d="M0,460 C320,400 640,470 960,430 C1280,392 1600,450 1920,410 L1920,1080 L0,1080 Z"
        fill="url(#h0)" filter="url(#soft)"/>
  <path d="M0,590 C300,525 560,610 860,560 C1180,505 1420,590 1920,530 L1920,1080 L0,1080 Z"
        fill="url(#h1)" filter="url(#soft)"/>
  <path d="M0,720 C360,650 640,750 980,690 C1320,632 1560,730 1920,660 L1920,1080 L0,1080 Z"
        fill="url(#h2)" filter="url(#soft)"/>
  <path d="M0,845 C420,775 760,885 1120,815 C1440,755 1680,855 1920,795 L1920,1080 L0,1080 Z"
        fill="url(#h3)" filter="url(#soft)"/>
  <path d="M0,955 C480,885 880,995 1280,925 C1560,877 1760,955 1920,915 L1920,1080 L0,1080 Z"
        fill="url(#h4)" filter="url(#soft)"/>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/headland-dark.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Headland (dark variant, rev 3): five dusk ridge layers filling the frame under a teal afterglow</title>
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0E1E2C"/>
      <stop offset="0.65" stop-color="#153349"/>
      <stop offset="1" stop-color="#1B4258"/>
    </linearGradient>
    <radialGradient id="afterglow" cx="0.68" cy="0.36" r="0.5">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.44"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="h0" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2F6DA0" stop-opacity="0.42"/>
      <stop offset="1" stop-color="#2F6DA0" stop-opacity="0.10"/>
    </linearGradient>
    <linearGradient id="h1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#24537D" stop-opacity="0.58"/>
      <stop offset="1" stop-color="#24537D" stop-opacity="0.16"/>
    </linearGradient>
    <linearGradient id="h2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1B4A66" stop-opacity="0.70"/>
      <stop offset="1" stop-color="#1B4A66" stop-opacity="0.24"/>
    </linearGradient>
    <linearGradient id="h3" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#17455C" stop-opacity="0.82"/>
      <stop offset="1" stop-color="#17455C" stop-opacity="0.32"/>
    </linearGradient>
    <linearGradient id="h4" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#102A40" stop-opacity="0.95"/>
      <stop offset="1" stop-color="#102A40" stop-opacity="0.55"/>
    </linearGradient>
    <linearGradient id="rim" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#4FBACD" stop-opacity="0"/>
      <stop offset="0.55" stop-color="#4FBACD" stop-opacity="0.8"/>
      <stop offset="1" stop-color="#4FBACD" stop-opacity="0"/>
    </linearGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="18"/></filter>
    <filter id="soft2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="4"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#sky)"/>
  <rect width="1920" height="1080" fill="url(#afterglow)"/>
  <path d="M0,460 C320,400 640,470 960,430 C1280,392 1600,450 1920,410 L1920,1080 L0,1080 Z"
        fill="url(#h0)" filter="url(#soft)"/>
  <path d="M0,590 C300,525 560,610 860,560 C1180,505 1420,590 1920,530 L1920,1080 L0,1080 Z"
        fill="url(#h1)" filter="url(#soft)"/>
  <path d="M0,720 C360,650 640,750 980,690 C1320,632 1560,730 1920,660 L1920,1080 L0,1080 Z"
        fill="url(#h2)" filter="url(#soft)"/>
  <path d="M0,845 C420,775 760,885 1120,815 C1440,755 1680,855 1920,795 L1920,1080 L0,1080 Z"
        fill="url(#h3)" filter="url(#soft)"/>
  <path d="M0,957 C480,887 880,997 1280,927 C1560,879 1760,957 1920,917"
        fill="none" stroke="url(#rim)" stroke-width="4" filter="url(#soft2)"/>
  <path d="M0,955 C480,885 880,995 1280,925 C1560,877 1760,955 1920,915 L1920,1080 L0,1080 Z"
        fill="url(#h4)" filter="url(#soft)"/>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/ripple-light.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Ripple (light variant, rev 3): arcs reaching the far corner, answered by a second ripple from the top right</title>
  <defs>
    <radialGradient id="bg" cx="0.05" cy="1.05" r="1.4">
      <stop offset="0" stop-color="#B7DCE3"/>
      <stop offset="0.55" stop-color="#98C6D5"/>
      <stop offset="1" stop-color="#7BAEC6"/>
    </radialGradient>
    <radialGradient id="core" cx="0.02" cy="1.02" r="0.5">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.38"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="core2" cx="0.99" cy="0.0" r="0.4">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.24"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="6"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#core)"/>
  <rect width="1920" height="1080" fill="url(#core2)"/>
  <g fill="none" filter="url(#soft)">
    <circle cx="30" cy="1100" r="280" stroke="#176E7E" stroke-width="34" opacity="0.55"/>
    <circle cx="30" cy="1100" r="470" stroke="#2190A4" stroke-width="28" opacity="0.46"/>
    <circle cx="30" cy="1100" r="660" stroke="#2B5D86" stroke-width="24" opacity="0.38"/>
    <circle cx="30" cy="1100" r="850" stroke="#2190A4" stroke-width="20" opacity="0.31"/>
    <circle cx="30" cy="1100" r="1040" stroke="#4A8ABD" stroke-width="17" opacity="0.25"/>
    <circle cx="30" cy="1100" r="1230" stroke="#2190A4" stroke-width="14" opacity="0.20"/>
    <circle cx="30" cy="1100" r="1420" stroke="#2B5D86" stroke-width="12" opacity="0.16"/>
    <circle cx="30" cy="1100" r="1610" stroke="#176E7E" stroke-width="10" opacity="0.13"/>
    <circle cx="30" cy="1100" r="1800" stroke="#2190A4" stroke-width="9" opacity="0.11"/>
    <circle cx="30" cy="1100" r="1990" stroke="#4A8ABD" stroke-width="8" opacity="0.09"/>
  </g>
  <g fill="none" filter="url(#soft)">
    <circle cx="1890" cy="-20" r="200" stroke="#2190A4" stroke-width="16" opacity="0.30"/>
    <circle cx="1890" cy="-20" r="360" stroke="#2B5D86" stroke-width="13" opacity="0.24"/>
    <circle cx="1890" cy="-20" r="520" stroke="#176E7E" stroke-width="11" opacity="0.18"/>
    <circle cx="1890" cy="-20" r="680" stroke="#2190A4" stroke-width="9" opacity="0.13"/>
  </g>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/ripple-dark.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Ripple (dark variant, rev 3): glowing arcs reaching the far corner, answered by a second ripple from the top right</title>
  <defs>
    <radialGradient id="bg" cx="0.05" cy="1.05" r="1.4">
      <stop offset="0" stop-color="#123240"/>
      <stop offset="0.55" stop-color="#0F2735"/>
      <stop offset="1" stop-color="#0D1F2E"/>
    </radialGradient>
    <radialGradient id="core" cx="0.02" cy="1.02" r="0.5">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="core2" cx="0.99" cy="0.0" r="0.4">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.32"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </radialGradient>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="6"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <rect width="1920" height="1080" fill="url(#core)"/>
  <rect width="1920" height="1080" fill="url(#core2)"/>
  <g fill="none" filter="url(#soft)">
    <circle cx="30" cy="1100" r="280" stroke="#4FBACD" stroke-width="34" opacity="0.60"/>
    <circle cx="30" cy="1100" r="470" stroke="#2F97A9" stroke-width="28" opacity="0.48"/>
    <circle cx="30" cy="1100" r="660" stroke="#4A8ABD" stroke-width="24" opacity="0.40"/>
    <circle cx="30" cy="1100" r="850" stroke="#4FBACD" stroke-width="20" opacity="0.33"/>
    <circle cx="30" cy="1100" r="1040" stroke="#2F97A9" stroke-width="17" opacity="0.26"/>
    <circle cx="30" cy="1100" r="1230" stroke="#4A8ABD" stroke-width="14" opacity="0.21"/>
    <circle cx="30" cy="1100" r="1420" stroke="#4FBACD" stroke-width="12" opacity="0.17"/>
    <circle cx="30" cy="1100" r="1610" stroke="#2F97A9" stroke-width="10" opacity="0.13"/>
    <circle cx="30" cy="1100" r="1800" stroke="#4A8ABD" stroke-width="9" opacity="0.11"/>
    <circle cx="30" cy="1100" r="1990" stroke="#4FBACD" stroke-width="8" opacity="0.09"/>
  </g>
  <g fill="none" filter="url(#soft)">
    <circle cx="1890" cy="-20" r="200" stroke="#4FBACD" stroke-width="16" opacity="0.34"/>
    <circle cx="1890" cy="-20" r="360" stroke="#4A8ABD" stroke-width="13" opacity="0.26"/>
    <circle cx="1890" cy="-20" r="520" stroke="#2F97A9" stroke-width="11" opacity="0.20"/>
    <circle cx="1890" cy="-20" r="680" stroke="#4FBACD" stroke-width="9" opacity="0.14"/>
  </g>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/curtain-light.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Curtain (light variant, rev 2): vivid aurora curtains in varied teals and blues on a saturated ground</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#B9DDE4"/>
      <stop offset="0.6" stop-color="#9FCEDA"/>
      <stop offset="1" stop-color="#83B9CC"/>
    </linearGradient>
    <linearGradient id="f1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.50"/>
      <stop offset="0.7" stop-color="#2190A4" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="f2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2B5D86" stop-opacity="0.44"/>
      <stop offset="0.7" stop-color="#2B5D86" stop-opacity="0.15"/>
      <stop offset="1" stop-color="#2B5D86" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="f3" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4A8ABD" stop-opacity="0.42"/>
      <stop offset="0.7" stop-color="#4A8ABD" stop-opacity="0.14"/>
      <stop offset="1" stop-color="#4A8ABD" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="f4" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#176E7E" stop-opacity="0.48"/>
      <stop offset="0.7" stop-color="#176E7E" stop-opacity="0.16"/>
      <stop offset="1" stop-color="#176E7E" stop-opacity="0"/>
    </linearGradient>
    <filter id="soft" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="26"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <g filter="url(#soft)">
    <rect x="100" y="-60" width="170" height="880" fill="url(#f2)" transform="skewX(-6)"/>
    <rect x="360" y="-60" width="250" height="1030" fill="url(#f1)" transform="skewX(-4)"/>
    <rect x="680" y="-60" width="140" height="800" fill="url(#f4)" transform="skewX(-7)"/>
    <rect x="930" y="-60" width="290" height="1080" fill="url(#f1)" transform="skewX(-3)"/>
    <rect x="1290" y="-60" width="170" height="880" fill="url(#f2)" transform="skewX(-6)"/>
    <rect x="1520" y="-60" width="220" height="980" fill="url(#f3)" transform="skewX(-5)"/>
    <rect x="1790" y="-60" width="160" height="900" fill="url(#f4)" transform="skewX(-4)"/>
  </g>
</svg>
EOF

cat > /usr/share/backgrounds/paradigmos/curtain-dark.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <title>ParadigmOS wallpaper — Curtain (dark variant, rev 2): vivid varied teal and blue curtains over a richer night ground</title>
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0C1D2B"/>
      <stop offset="0.6" stop-color="#113049"/>
      <stop offset="1" stop-color="#1A4460"/>
    </linearGradient>
    <linearGradient id="f1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2F97A9" stop-opacity="0.60"/>
      <stop offset="0.7" stop-color="#2F97A9" stop-opacity="0.20"/>
      <stop offset="1" stop-color="#2F97A9" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="f2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4A8ABD" stop-opacity="0.50"/>
      <stop offset="0.7" stop-color="#4A8ABD" stop-opacity="0.16"/>
      <stop offset="1" stop-color="#4A8ABD" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="f3" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4FBACD" stop-opacity="0.58"/>
      <stop offset="0.7" stop-color="#4FBACD" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#4FBACD" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="f4" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2190A4" stop-opacity="0.55"/>
      <stop offset="0.7" stop-color="#2190A4" stop-opacity="0.18"/>
      <stop offset="1" stop-color="#2190A4" stop-opacity="0"/>
    </linearGradient>
    <filter id="soft" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="26"/></filter>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <g filter="url(#soft)">
    <rect x="100" y="-60" width="170" height="880" fill="url(#f2)" transform="skewX(-6)"/>
    <rect x="360" y="-60" width="250" height="1030" fill="url(#f1)" transform="skewX(-4)"/>
    <rect x="680" y="-60" width="140" height="800" fill="url(#f3)" transform="skewX(-7)"/>
    <rect x="930" y="-60" width="290" height="1080" fill="url(#f4)" transform="skewX(-3)"/>
    <rect x="1290" y="-60" width="170" height="880" fill="url(#f2)" transform="skewX(-6)"/>
    <rect x="1520" y="-60" width="220" height="980" fill="url(#f3)" transform="skewX(-5)"/>
    <rect x="1790" y="-60" width="160" height="900" fill="url(#f1)" transform="skewX(-4)"/>
  </g>
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
  <g fill="#4A8ABD">
    <rect x="80" y="48" width="24" height="24" rx="6"/>
    <rect x="48" y="80" width="24" height="24" rx="6"/>
    <rect x="80" y="80" width="24" height="24" rx="6"/>
  </g>
  <rect x="80" y="16" width="24" height="24" rx="6" fill="#2190A4"
        transform="translate(9,-7) rotate(14 92 28)"/>
</svg>
EOF
cp /usr/share/icons/hicolor/scalable/apps/paradigmos-logo.svg \
   /usr/share/icons/hicolor/scalable/apps/fedora-logo-icon.svg
# The live installer launcher (liveinst.desktop, "Install to hard drive")
# asks for Icon=org.fedoraproject.AnacondaInstaller, which NO package ships
# as an icon — GNOME fell back to a generic cog (Elliott's find, build 7).
# Ship the mark under that name, and over anaconda's own icon name too;
# drop the stock fixed-size PNGs so the scalable SVG serves every size.
cp /usr/share/icons/hicolor/scalable/apps/paradigmos-logo.svg \
   /usr/share/icons/hicolor/scalable/apps/org.fedoraproject.AnacondaInstaller.svg
cp /usr/share/icons/hicolor/scalable/apps/paradigmos-logo.svg \
   /usr/share/icons/hicolor/scalable/apps/anaconda.svg
rm -f /usr/share/icons/hicolor/48x48/apps/anaconda.png \
      /usr/share/icons/oxygen/48x48/apps/anaconda.png
gtk-update-icon-cache -f /usr/share/icons/hicolor || true

mkdir -p /usr/share/gnome-background-properties
cat > /usr/share/gnome-background-properties/paradigmos.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>Shift</name>
    <filename>/usr/share/backgrounds/paradigmos/shift-light.svg</filename>
    <filename-dark>/usr/share/backgrounds/paradigmos/shift-dark.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#2190A4</pcolor>
    <scolor>#1A3F5F</scolor>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Aurora</name>
    <filename>/usr/share/backgrounds/paradigmos/aurora-1-light.svg</filename>
    <filename-dark>/usr/share/backgrounds/paradigmos/aurora-1-dark.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#2190A4</pcolor>
    <scolor>#2B5D86</scolor>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Headland</name>
    <filename>/usr/share/backgrounds/paradigmos/headland-light.svg</filename>
    <filename-dark>/usr/share/backgrounds/paradigmos/headland-dark.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#176E7E</pcolor>
    <scolor>#1A3F5F</scolor>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Ripple</name>
    <filename>/usr/share/backgrounds/paradigmos/ripple-light.svg</filename>
    <filename-dark>/usr/share/backgrounds/paradigmos/ripple-dark.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#2190A4</pcolor>
    <scolor>#123240</scolor>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Curtain</name>
    <filename>/usr/share/backgrounds/paradigmos/curtain-light.svg</filename>
    <filename-dark>/usr/share/backgrounds/paradigmos/curtain-dark.svg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
    <pcolor>#2F97A9</pcolor>
    <scolor>#113049</scolor>
  </wallpaper>
</wallpapers>
EOF

# The five ParadigmOS sets are the ONLY wallpapers offered in Settings >
# Appearance (Elliott, 2026-07-16 — stock ones mixed ours all through the
# grid). Dropping the registration XMLs removes them from the picker; the
# image files stay on disk, which is cheap and keeps anything that
# references them directly (e.g. GNOME's default-wallpaper fallback) safe.
find /usr/share/gnome-background-properties -name '*.xml' \
     ! -name 'paradigmos.xml' -delete

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
# Default wallpaper: Shift (Elliott's pick, 2026-07-16 — previously Aurora).
picture-uri='file:///usr/share/backgrounds/paradigmos/shift-light.svg'
picture-uri-dark='file:///usr/share/backgrounds/paradigmos/shift-dark.svg'
picture-options='zoom'

[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com']

[org/gnome/desktop/wm/preferences]
# Minimize/maximize window buttons visible by default (Elliott, 2026-07-16).
# GNOME ships close-only and Settings has no toggle for this (only GNOME
# Tweaks does), so the default is what most users will live with.
button-layout='appicon:minimize,maximize,close'

[org/gnome/desktop/a11y]
# The actual "Always Show Accessibility Menu" toggle from Settings >
# Accessibility (Elliott, 2026-07-16). Note: this was previously assumed
# to be toolkit-accessibility below — wrong key, hence build ≤7 shipped
# with the menu auto-hiding.
always-show-universal-access-status=true

[org/gnome/desktop/interface]
# Keep the AT-SPI accessibility stack always on
toolkit-accessibility=true
# No top-left hot corner for the Activities overview (Elliott, 2026-07-16);
# users can re-enable it in Settings > Multitasking.
enable-hot-corners=false
# Brand accent: GNOME's stock teal (#2190A4), which IS the brand teal —
# Elliott aligned the palette to it (2026-07-10) so the supported accent
# system matches the mark/wallpapers exactly. Enum value, not hex; users
# can still change it in Settings > Appearance.
accent-color='teal'
EOF
dconf update

# gnome-initial-setup runs with its own dconf profile
# (/usr/share/dconf/profile/gnome-initial-setup) which chains ONLY
# user-db:user + its own defaults file — NOT system-db:local. So nothing
# above applied during first-boot setup, and the screen-reader flag an
# accessible install carries over stayed invisible there too: Orca was
# silent at the "Welcome to ParadigmOS" setup screen until toggled by hand
# (Elliott's build-7 install test). /etc/dconf/profile/ takes precedence
# over /usr/share/dconf/profile/, so ship an override that inserts
# system-db:local while keeping upstream's initial-setup defaults.
# (GDM's own profile already chains system-db:local — login screen is fine.)
cat > /etc/dconf/profile/gnome-initial-setup << 'EOF'
user-db:user
system-db:local
file-db:/usr/share/gnome-initial-setup/initial-setup-dconf-defaults
EOF

# ---- Accessibility: screen-reader boot entry plumbing ----
# The ISO boot menus (BIOS + UEFI) carry a "Start ... with screen reader
# (press S)" entry — added by build/patch-lorax-a11y.py at ISO build time —
# whose only difference is the kernel arg paradigmos.a11y=screenreader.
# This service notices that arg before GDM starts and flips the GNOME
# screen-reader default on system-wide, so Orca is already talking when the
# live session (and the installer inside it) comes up. Without the arg the
# service is inert; Super+Alt+S still toggles Orca manually either way.
mkdir -p /usr/libexec/paradigmos
cat > /usr/libexec/paradigmos/a11y-boot << 'EOF'
#!/usr/bin/bash
set -eu
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/20-paradigmos-a11y << 'DCONF'
[org/gnome/desktop/a11y/applications]
screen-reader-enabled=true
DCONF
dconf update
EOF
chmod +x /usr/libexec/paradigmos/a11y-boot

cat > /etc/systemd/system/paradigmos-a11y-boot.service << 'EOF'
[Unit]
Description=Enable the screen reader when booted with paradigmos.a11y=screenreader
ConditionKernelCommandLine=paradigmos.a11y=screenreader
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/libexec/paradigmos/a11y-boot

[Install]
WantedBy=graphical.target
EOF
systemctl enable paradigmos-a11y-boot.service

# A live install copies the pristine image, not the running overlay, so the
# dconf flip above would NOT survive onto the installed system by itself.
# Anaconda runs every /usr/share/anaconda/post-scripts/*.ks at install time
# (livesys-scripts uses the same hook to remove the live user): if this
# install was accessible — booted via the screen-reader menu entry OR the
# user turned Orca on inside the live session — make the installed system
# speak from its first boot too, GDM and gnome-initial-setup included
# (both chain system-db:local; g-i-s via our profile override above).
# (Written with @POST@/@END@ placeholders because pykickstart's section
# parser is line-based and would treat literal %post/%end lines inside this
# heredoc as terminating THIS %post section — build 3 failed exactly there.)
mkdir -p /usr/share/anaconda/post-scripts
cat > /usr/share/anaconda/post-scripts/70-paradigmos-a11y.ks << 'EOF'
@POST@ --nochroot
carry=no
grep -q 'paradigmos.a11y=screenreader' /proc/cmdline && carry=yes
if [ "$carry" = no ]; then
    # Manual-Orca case: read the live user's own setting off their session
    # bus (Super+Alt+S flips exactly this key). Best-effort — any failure
    # just means no carry-over, never a failed install.
    uid="$(id -u liveuser 2>/dev/null || true)"
    if [ -n "$uid" ]; then
        state="$(runuser -u liveuser -- env "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus" \
            gsettings get org.gnome.desktop.a11y.applications screen-reader-enabled 2>/dev/null || true)"
        [ "$state" = "true" ] && carry=yes
    fi
fi
if [ "$carry" = yes ]; then
    mkdir -p "$ANA_INSTALL_PATH/etc/dconf/db/local.d"
    cat > "$ANA_INSTALL_PATH/etc/dconf/db/local.d/20-paradigmos-a11y" << 'DCONF'
[org/gnome/desktop/a11y/applications]
screen-reader-enabled=true
DCONF
    chroot "$ANA_INSTALL_PATH" dconf update
fi
@END@
EOF
sed -i 's/^@POST@/%post/; s/^@END@/%end/' \
    /usr/share/anaconda/post-scripts/70-paradigmos-a11y.ks

# ---- Third-party repositories: enabled out of the box ----
# Elliott's call (2026-07-16): pre-answer Fedora's third-party question so
# gnome-initial-setup skips its "Third-Party Repositories" page entirely
# (the page only shows while the state is unconfigured). This enables
# Fedora's curated extras — Google Chrome repo, NVIDIA driver + Steam
# repos from RPM Fusion nonfree, PyCharm copr, unfiltered Flathub. Full
# RPM Fusion free/nonfree is already enabled via the release packages in
# the image. Offline-safe: only flips repo/flatpak config and records the
# state; nothing is downloaded here.
fedora-third-party enable

# ---- Installer completion message: say HOW to restart ----
# anaconda-webui's final screen says only "To begin using ParadigmOS 1.0
# (Aurora), reboot your system." — no Restart button, no hint where restart
# lives (upstream RFE drafted in docs/upstream-issues.md). Until upstream
# grows a button, make the English message actionable. The webui bundle
# ships gzipped; the $0 below is the message's product-name placeholder,
# NOT a shell expansion (single quotes). Non-English locales keep the
# stock wording (translations load from po.*.js). Build verification
# greps the image for the new string, so a changed upstream msgid can't
# silently ship the stale message.
WEBUI_BUNDLE=/usr/share/cockpit/anaconda-webui/index.js
gunzip "${WEBUI_BUNDLE}.gz"
sed -i 's/To begin using $0, reboot your system\./To begin using $0, restart your system: press Ctrl+Alt+Delete and activate Restart./' \
    "$WEBUI_BUNDLE"
gzip -9 "$WEBUI_BUNDLE"

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
#   paradigmos.conf profile's [User Interface] hooks (the profile itself
#   ships above since build 7).
# TODO(theme): branded GNOME theme + first-class high-contrast variant.
# TODO(plymouth): ParadigmOS boot splash.
# TODO(snapshots): preinstall and configure btrfs snapshot tooling (snapper
#   or btrfs-assistant) for automatic pre-update snapshots per spec.

%end
