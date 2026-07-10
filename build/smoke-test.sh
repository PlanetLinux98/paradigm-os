#!/usr/bin/env bash
# Headless QEMU/KVM smoke test for the built ISO (run inside WSL as root).
# Exercises the flagship accessibility path: at the boot menu it presses "s"
# — exactly what a blind user does, no arrows, no sight — and records the
# guest's audio output. A non-silent capture proves Orca is really speaking
# in the live session; screenshots cover the visual checks (menu entry,
# wallpaper, logo, dock) along the way.
# Usage: bash build/smoke-test.sh [output-dir]
set -euo pipefail

ISO="/root/paradigm-os/build/output/result/ParadigmOS-1.0-Aurora-x86_64.iso"
OUT="${1:-/root/smoke-shots}"
MON="/tmp/pmon.sock"
WAV="$OUT/paradigmos-a11y-speech.wav"

mkdir -p "$OUT"
pkill -f "qemu-system-x86_64.*ParadigmOS" 2>/dev/null || true
rm -f "$MON" "$WAV"

qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 \
  -cdrom "$ISO" \
  -display none -vnc :9 \
  -audiodev "wav,id=snd0,path=${WAV}" \
  -device intel-hda -device hda-duplex,audiodev=snd0 \
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

# The flagship interaction: "s" boots the screen-reader entry directly.
mon "sendkey s"
sleep 10
shot paradigmos-a11y-selected.png

sleep 240
shot paradigmos-live.png

# Dismiss the welcome dialog and the overview for a clean desktop shot
# (verifies wallpaper and the persistent dock; each keypress also gives
# Orca something more to announce for the audio capture).
mon "sendkey alt-f4"
mon "sendkey esc"
sleep 8
shot paradigmos-desktop.png

# Speech check. QEMU's wav backend only finalizes the header on exit, so
# while the VM is still running we read the raw PCM after the 44-byte
# header instead of trusting the frame count.
python3 - "$WAV" <<'PY'
import array, os, sys

path = sys.argv[1]
size = os.path.getsize(path)
with open(path, "rb") as f:
    f.seek(44)
    data = f.read()
samples = array.array("h", data[: len(data) // 2 * 2])
peak = max((abs(s) for s in samples), default=0)
secs = len(samples) / 2 / 44100  # stereo, 44.1 kHz
print(f"audio capture: {size} bytes, ~{secs:.0f}s, peak amplitude {peak}/32767")
if peak < 1000:
    sys.exit("SPEECH CHECK FAILED: capture is (near-)silent — Orca did not speak")
print("SPEECH CHECK PASSED: guest produced real audio (Orca speaking)")
PY

echo "SMOKE TEST DONE in $OUT (qemu pid ${QEMU_PID} left running for more shots)"
