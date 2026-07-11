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

# pcspk-audiodev routes the emulated PC speaker into the same capture, so
# the GRUB boot-menu beep cue is recorded alongside Orca's speech.
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 \
  -machine pcspk-audiodev=snd0 \
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

# Audio checks. QEMU's wav backend only finalizes the header on exit, so
# while the VM is still running we read the raw PCM after the 44-byte
# header instead of trusting the frame count. Segments are printed with
# timestamps: the GRUB beep cue should appear as a short blip near the
# start of the capture, Orca's speech as long segments later.
python3 - "$WAV" <<'PY'
import array, sys

path = sys.argv[1]
with open(path, "rb") as f:
    f.seek(44)
    data = f.read()
samples = array.array("h", data[: len(data) // 2 * 2])
rate = 44100 * 2  # stereo samples per second
win = rate // 2   # half-second windows
peaks = [max((abs(s) for s in samples[i : i + win]), default=0)
         for i in range(0, len(samples), win)]
thr = 1000
segments, start = [], None
for n, p in enumerate(peaks):
    if p > thr and start is None:
        start = n
    elif p <= thr and start is not None:
        segments.append((start, n))
        start = None
if start is not None:
    segments.append((start, len(peaks)))

print(f"audio capture: ~{len(samples) / rate:.0f}s, non-silent segments:")
for s, e in segments:
    print(f"  {s / 2:7.1f}s - {e / 2:7.1f}s  peak {max(peaks[s:e])}/32767")

total = sum(e - s for s, e in segments) / 2
overall = max(peaks, default=0)
if total < 3 or overall < 5000:
    sys.exit("SPEECH CHECK FAILED: no sustained audio — Orca did not speak")
print(f"SPEECH CHECK PASSED: {total:.1f}s of real audio, peak {overall}/32767")
if segments and segments[0][0] / 2 <= 5 and (segments[0][1] - segments[0][0]) / 2 <= 2:
    print("BEEP CUE DETECTED: short blip at start of capture (boot-menu beep)")
else:
    print("BEEP CUE NOT DETECTED in early capture — verify the grub beep manually")
PY

echo "SMOKE TEST DONE in $OUT (qemu pid ${QEMU_PID} left running for more shots)"
