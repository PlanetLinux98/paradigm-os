#!/usr/bin/env bash
# Headless QEMU/KVM smoke test for the built ISO (run inside WSL as root).
# Boots the live ISO, screenshots the boot menu and (later) the live session.
# Usage: bash build/smoke-test.sh [output-dir]
set -euo pipefail

ISO="/root/paradigm-os/build/output/result/ParadigmOS-1.0-Aurora-x86_64.iso"
OUT="${1:-/root/smoke-shots}"
MON="/tmp/pmon.sock"

mkdir -p "$OUT"
pkill -f "qemu-system-x86_64.*ParadigmOS" 2>/dev/null || true
rm -f "$MON"

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 \
  -cdrom "$ISO" \
  -display none -vnc :9 \
  -monitor "unix:${MON},server,nowait" \
  > /root/qemu-smoke.log 2>&1 &
QEMU_PID=$!
echo "qemu started (pid ${QEMU_PID})"

shot() {
  echo "screendump /tmp/shot.ppm" | socat - "UNIX-CONNECT:${MON}"
  sleep 2
  convert /tmp/shot.ppm "$OUT/$1"
  echo "captured $1"
}

mon() {
  echo "$1" | socat - "UNIX-CONNECT:${MON}"
  sleep 2
}

sleep 25
shot paradigmos-boot-menu.png

sleep 240
shot paradigmos-live.png

# Dismiss the welcome dialog and the overview for a clean desktop shot
# (verifies wallpaper and whether the persistent dock is active).
mon "sendkey alt-f4"
mon "sendkey esc"
sleep 4
shot paradigmos-desktop.png

echo "SMOKE TEST SHOTS DONE in $OUT (qemu pid ${QEMU_PID} left running for more shots)"
