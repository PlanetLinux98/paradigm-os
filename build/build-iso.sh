#!/usr/bin/env bash
# Build the ParadigmOS live ISO inside a fedora:44 container.
#
# Run from the repo root, inside WSL2 (or any Linux with Docker):
#   bash build/build-iso.sh
#
# Output lands in build/output/ (gitignored).

# -x tracing: the outer steps are few, and the trace has already been needed
# once to debug silent-success behavior in the container plumbing.
set -euxo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEDORA_VERSION=44
OS_VERSION="1.0"
CODENAME="Aurora"
RESULT_DIR="${REPO_ROOT}/build/output/result"

# ---- Build identity ---------------------------------------------------------
# The human build number lives in build/BUILD_NUMBER (bumped deliberately per
# verified build); the git hash and date are stamped automatically so every
# ISO records exactly what produced it. Spelled out as "build N" — not "bN",
# which reads like "beta N" (Elliott, 2026-07-11).
BUILD_NUMBER="$(tr -d '[:space:]' < "${REPO_ROOT}/build/BUILD_NUMBER")"
GIT_HASH="$(git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
BUILD_DATE="$(date +%Y-%m-%d)"
BUILD_ID="${BUILD_NUMBER}.$(date +%Y%m%d).g${GIT_HASH}"
BUILD_INFO="ParadigmOS ${OS_VERSION} (${CODENAME}), build ${BUILD_NUMBER} — built ${BUILD_DATE} from git ${GIT_HASH}"
ISO_NAME="ParadigmOS-${OS_VERSION}-${CODENAME}-build${BUILD_NUMBER}-x86_64.iso"

# livemedia-creator refuses to start if the result dir exists at all,
# so clear leftovers from any previous attempt.
rm -rf "${RESULT_DIR}"
mkdir -p "${REPO_ROOT}/build/output"

# Stamp the kickstart: the repo copy keeps @BUILDID@/@BUILDINFO@ placeholders
# (it stays hermetic and diff-friendly); the build feeds lmc this filled copy.
STAMPED_KS="build/output/paradigmos-stamped.ks"
sed "s|@BUILDID@|${BUILD_ID}|; s|@BUILDINFO@|${BUILD_INFO}|" \
  "${REPO_ROOT}/kickstart/paradigmos.ks" > "${REPO_ROOT}/${STAMPED_KS}"

# --releasever feeds the boot-menu title ("Start ParadigmOS 1.0 (build N)")
# rather than the Fedora release: safe here because every repo URL in the
# kickstart is hardcoded — none rely on $releasever substitution.
#
# --privileged is required: livemedia-creator --no-virt loop-mounts images
# and runs Anaconda directly inside the container.
docker run --rm --privileged \
  -v "${REPO_ROOT}:/paradigm" \
  -w /paradigm \
  "fedora:${FEDORA_VERSION}" \
  bash -euxc "
    dnf install -y lorax-lmc-novirt policycoreutils pykickstart
    # Fail on kickstart parse errors up front instead of mid-run (build 3
    # died on one after the full toolchain install).
    ksvalidator -v F44 '${STAMPED_KS}'
    # Flagship accessibility: add the 'with screen reader (press S)' entry,
    # the menu beep cue, and the 120s timeout to the BIOS+UEFI boot menus
    # before the ISO is assembled.
    python3 build/patch-lorax-a11y.py
    livemedia-creator \
      --ks '${STAMPED_KS}' \
      --no-virt \
      --make-iso \
      --iso-only \
      --iso-name '${ISO_NAME}' \
      --project ParadigmOS \
      --releasever '${OS_VERSION} (build ${BUILD_NUMBER})' \
      --volid 'ParadigmOS-${OS_VERSION}-build${BUILD_NUMBER}' \
      --resultdir /paradigm/build/output/result \
      --logfile /paradigm/build/output/lmc-logs/livemedia.log
  "

# livemedia-creator exits 0 on some early aborts, so the ISO's existence is
# the only trustworthy success signal.
if [[ -f "${RESULT_DIR}/${ISO_NAME}" ]]; then
  echo "BUILD SUCCEEDED: ${RESULT_DIR}/${ISO_NAME} (${BUILD_INFO})"
else
  echo "BUILD FAILED: no ISO at ${RESULT_DIR}/${ISO_NAME} — check build/output/lmc-logs/" >&2
  exit 1
fi
