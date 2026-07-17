#!/usr/bin/env bash
# Automated QEMU install test for the built ISO (run inside WSL as root).
#
# Three phases:
#   1. INSTALL  — boot the live ISO (direct kernel boot, UEFI/OVMF) with the
#                 screen-reader kernel arg and a root debug shell on ttyS1,
#                 then run a fully unattended `liveinst --kickstart` install
#                 onto a fresh virtual disk. The kickstart's `shutdown`
#                 powers the VM off when it finishes.
#   2. FIRSTBOOT — boot the installed disk with audio capture + periodic
#                 screenshots: does gnome-initial-setup come up, does Orca
#                 speak there, which pages appear?
#   3. INSPECT  — boot the live ISO again with the installed disk attached
#                 and read the interesting files off it (third-party state,
#                 dconf carry-over, logs).
#
# Usage: bash build/install-test.sh [output-dir]
# Results land in the output dir (default /root/install-test): logs,
# screenshots, firstboot.wav, inspect.log. Exit 0 = all phases ran; the
# captured evidence still needs eyeballing (this is a diagnostic harness,
# not a pass/fail gate — the checks that can be automatic are printed).
set -euo pipefail

ISO="$(ls -t /root/paradigm-os/build/output/result/ParadigmOS-*.iso | head -1)"
OUT="${1:-/root/install-test}"
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS=/usr/share/OVMF/OVMF_VARS_4M.fd
HTTP_PORT=8021

rm -rf "$OUT"; mkdir -p "$OUT"
cd "$OUT"
pkill -f "qemu-system-x86_64.*install-test" 2>/dev/null || true

echo "== ISO: $ISO"
VOLID="$(blkid -o value -s LABEL "$ISO" 2>/dev/null || true)"
[ -n "$VOLID" ] || VOLID="$(basename "$ISO" | sed 's/ParadigmOS-\(.*\)-Aurora-\(build[0-9]*\)-x86_64.iso/ParadigmOS-\1-\2/')"
echo "== volid: $VOLID"

# Kernel + initrd straight off the ISO (direct kernel boot = we control args)
mkdir -p /mnt/itiso
mountpoint -q /mnt/itiso && umount /mnt/itiso
mount -o loop,ro "$ISO" /mnt/itiso
cp /mnt/itiso/images/pxeboot/vmlinuz /mnt/itiso/images/pxeboot/initrd.img .
umount /mnt/itiso

# Fresh 20G disk + private copy of UEFI vars
qemu-img create -f qcow2 disk.qcow2 20G
cp "$OVMF_VARS" vars.fd

# The unattended install answer file. No `user` line on purpose: mirrors a
# webui live install, so gnome-initial-setup runs in new-user mode on first
# boot (that is exactly the flow under test).
cat > test-install.ks <<'KS'
cmdline
lang en_CA.UTF-8
keyboard us
timezone America/Toronto
rootpw --lock
# vda is the target disk; vdb is the live ISO attached as a read-only
# virtio disk (QEMU's emulated CD drive never shows up under OVMF +
# direct kernel boot here, so the harness serves the ISO as a disk —
# dracut's CDLABEL match works on any block device).
ignoredisk --only-use=vda
zerombr
clearpart --all --initlabel
autopart
shutdown
KS

# Serve the kickstart to the guest (10.0.2.2 = host in QEMU user networking)
python3 -m http.server "$HTTP_PORT" --directory "$OUT" &>/dev/null &
HTTP_PID=$!
trap 'kill $HTTP_PID 2>/dev/null || true' EXIT

# ---------- phase 1: install ----------
echo "== phase 1: unattended install (this takes 10-20 min)"
qemu-system-x86_64 -name install-test-p1 \
  -enable-kvm -m 4096 -smp 2 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file=vars.fd \
  -kernel vmlinuz -initrd initrd.img \
  -append "root=live:CDLABEL=${VOLID} rd.live.image quiet console=ttyS0 systemd.debug_shell=ttyS1 paradigmos.a11y=screenreader" \
  -drive file=disk.qcow2,if=virtio,format=qcow2 \
  -drive file="$ISO",if=virtio,format=raw,readonly=on \
  -display none -vnc :9 \
  -serial file:ser0-console.log \
  -serial unix:ser1.sock,server,nowait \
  -monitor unix:mon.sock,server,nowait \
  &> qemu-p1.log &
QPID=$!

# Drive the root debug shell on ttyS1: fetch the kickstart, launch liveinst.
python3 - <<'PY'
import socket, time, sys, os

def connect(path, tries=120):
    for _ in range(tries):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(path)
            return s
        except OSError:
            time.sleep(1)
    sys.exit("could not connect to ttyS1 socket")

s = connect("ser1.sock")
s.settimeout(5)
log = open("ser1-shell.log", "wb")

def drain(seconds):
    end = time.time() + seconds
    buf = b""
    while time.time() < end:
        try:
            d = s.recv(4096)
            if d:
                buf += d
                log.write(d); log.flush()
        except socket.timeout:
            pass
    return buf

def send(line):
    s.sendall(line.encode() + b"\n")

# Give the live system time to reach the debug shell, then poke it.
print("waiting 120s for live boot...")
time.sleep(120)
for attempt in range(20):
    send("echo SHELL-ALIVE-$((6*7))")
    out = drain(6)
    if b"SHELL-ALIVE-42" in out:
        print("debug shell is up")
        break
    time.sleep(10)
else:
    sys.exit("debug shell never answered")

send("curl -s -o /tmp/ks.cfg http://10.0.2.2:8021/test-install.ks && echo KS-FETCHED")
out = drain(10)
if b"KS-FETCHED" not in out:
    sys.exit("kickstart fetch failed")
print("kickstart fetched; starting liveinst")
send("liveinst --kickstart /tmp/ks.cfg > /tmp/liveinst.log 2>&1; echo LIVEINST-RC=$?; tail -5 /tmp/liveinst.log > /dev/ttyS1")
# From here the kickstart's `shutdown` should power the VM off; the shell
# output (if the install errors out first) lands in ser1-shell.log.
end = time.time() + 60
while time.time() < end:
    try:
        d = s.recv(4096)
        if d:
            log.write(d); log.flush()
    except socket.timeout:
        pass
    except OSError:
        break
print("driver detaching; waiting for VM to power off on its own")
PY

# Wait (up to 30 min) for the ks `shutdown` to end the VM
for i in $(seq 1 180); do
  kill -0 "$QPID" 2>/dev/null || break
  sleep 10
  if [ $((i % 18)) -eq 0 ]; then
    echo "screendump p1-progress-$i.ppm" | socat - "UNIX-CONNECT:mon.sock" || true
    echo "  ...still installing ($((i*10))s)"
  fi
done
if kill -0 "$QPID" 2>/dev/null; then
  echo "screendump p1-timeout.ppm" | socat - "UNIX-CONNECT:mon.sock" || true
  sleep 2
  kill "$QPID"
  echo "PHASE 1 FAILED: install did not power off within 30 min (see ser1-shell.log, p1-timeout.ppm)"
  exit 1
fi
echo "== phase 1 done: VM powered off (install finished or aborted — evidence below)"

# ---------- phase 2: first boot of the installed system ----------
echo "== phase 2: first boot, capturing audio + screenshots (4 min)"
qemu-system-x86_64 -name install-test-p2 \
  -enable-kvm -m 4096 -smp 2 \
  -machine pcspk-audiodev=snd0 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file=vars.fd \
  -drive file=disk.qcow2,if=virtio,format=qcow2 \
  -display none -vnc :9 \
  -audiodev "wav,id=snd0,path=firstboot.wav" \
  -device intel-hda -device hda-duplex,audiodev=snd0 \
  -monitor unix:mon2.sock,server,nowait \
  &> qemu-p2.log &
QPID2=$!
for t in 60 120 180 240; do
  sleep 60
  echo "screendump p2-firstboot-${t}s.ppm" | socat - "UNIX-CONNECT:mon2.sock" || true
done
sleep 2
kill "$QPID2" 2>/dev/null || true
wait "$QPID2" 2>/dev/null || true

python3 - firstboot.wav <<'PY' || true
import array, sys
with open(sys.argv[1], "rb") as f:
    f.seek(44)
    data = f.read()
samples = array.array("h", data[: len(data) // 2 * 2])
rate = 44100 * 2
win = rate // 2
peaks = [max((abs(x) for x in samples[i:i+win]), default=0) for i in range(0, len(samples), win)]
thr = 1000
loud = sum(1 for p in peaks if p > thr) / 2.0
print(f"firstboot audio: ~{len(samples)/rate:.0f}s captured, {loud:.1f}s above threshold, peak {max(peaks, default=0)}/32767")
print("FIRSTBOOT SPEECH: " + ("YES - something is talking" if loud >= 3 else "NO - effectively silent"))
PY

# ---------- phase 3: offline inspection of the installed disk ----------
echo "== phase 3: mounting the installed disk from a live boot"
qemu-system-x86_64 -name install-test-p3 \
  -enable-kvm -m 4096 -smp 2 \
  -kernel vmlinuz -initrd initrd.img \
  -append "root=live:CDLABEL=${VOLID} rd.live.image quiet console=ttyS0 systemd.debug_shell=ttyS1 3" \
  -drive file=disk.qcow2,if=virtio,format=qcow2 \
  -drive file="$ISO",if=virtio,format=raw,readonly=on \
  -display none -vnc :9 \
  -serial file:ser0-p3.log \
  -serial unix:ser3.sock,server,nowait \
  -monitor unix:mon3.sock,server,nowait \
  &> qemu-p3.log &
QPID3=$!

python3 - <<'PY'
import socket, time, sys

def connect(path, tries=120):
    for _ in range(tries):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(path); return s
        except OSError:
            time.sleep(1)
    sys.exit("no ttyS1 socket in phase 3")

s = connect("ser3.sock"); s.settimeout(5)
log = open("inspect.log", "wb")

def drain(seconds):
    end = time.time() + seconds; buf = b""
    while time.time() < end:
        try:
            d = s.recv(4096)
            if d: buf += d; log.write(d); log.flush()
        except socket.timeout: pass
    return buf

def send(line): s.sendall(line.encode() + b"\n")

print("waiting 90s for phase-3 live boot...")
time.sleep(90)
for _ in range(20):
    send("echo SHELL-ALIVE-$((6*7))")
    if b"SHELL-ALIVE-42" in drain(6): break
    time.sleep(10)
else:
    sys.exit("phase-3 debug shell never answered")

cmds = [
    "lsblk -o NAME,SIZE,FSTYPE,LABEL /dev/vda",
    "mkdir -p /m && (mount -o subvol=root /dev/vda3 /m || mount /dev/vda3 /m) && echo MOUNTED",
    "echo '--- third-party state:' && cat /m/var/lib/fedora-third-party/state",
    "echo '--- dconf local.d:' && ls -la /m/etc/dconf/db/local.d/",
    "echo '--- carry file:' && cat /m/etc/dconf/db/local.d/20-paradigmos-a11y",
    "echo '--- carry breadcrumb:' && cat /m/var/log/paradigmos-a11y-carry.log",
    "echo '--- g-i-s dconf profile:' && cat /m/etc/dconf/profile/gnome-initial-setup",
    "echo '--- os-release build:' && grep BUILD_ID /m/usr/lib/os-release",
    "echo '--- anaconda ks post log:' && grep -l . /m/var/log/anaconda/ks-script-*.log 2>/dev/null | head -5",
    "echo INSPECT-DONE",
]
for c in cmds:
    send(c)
    drain(8)
print("phase 3 inspection commands sent; see inspect.log")
PY

kill "$QPID3" 2>/dev/null || true
wait "$QPID3" 2>/dev/null || true

for p in p1-timeout p1-progress-18 p1-progress-36 p2-firstboot-60s p2-firstboot-120s p2-firstboot-180s p2-firstboot-240s; do
  [ -f "$p.ppm" ] && convert "$p.ppm" "$p.png" && rm -f "$p.ppm"
done

echo "== INSTALL TEST COMPLETE — evidence in $OUT:"
ls -la "$OUT" | grep -Ev "vmlinuz|initrd|vars.fd|disk.qcow2"
