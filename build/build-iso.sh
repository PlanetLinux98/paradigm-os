#!/usr/bin/env bash
# Build the ParadigmOS live ISO inside a fedora:44 container.
#
# Run from the repo root, inside WSL2 (or any Linux with Docker):
#   bash build/build-iso.sh
#
# Output lands in build/output/ (gitignored).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEDORA_VERSION=44
OS_VERSION="1.0"
CODENAME="Aurora"
ISO_NAME="ParadigmOS-${OS_VERSION}-${CODENAME}-x86_64.iso"

mkdir -p "${REPO_ROOT}/build/output"

# --privileged is required: livemedia-creator --no-virt loop-mounts images
# and runs Anaconda directly inside the container.
docker run --rm --privileged \
  -v "${REPO_ROOT}:/paradigm" \
  -w /paradigm \
  "fedora:${FEDORA_VERSION}" \
  bash -euxc "
    dnf install -y lorax-lmc-novirt
    livemedia-creator \
      --ks kickstart/paradigmos.ks \
      --no-virt \
      --make-iso \
      --iso-only \
      --iso-name '${ISO_NAME}' \
      --project ParadigmOS \
      --releasever ${FEDORA_VERSION} \
      --volid 'ParadigmOS-${OS_VERSION}' \
      --resultdir /paradigm/build/output/result \
      --logfile /paradigm/build/output/lmc-logs/livemedia.log
  "

echo
echo \"Done. ISO (if the build succeeded): build/output/result/${ISO_NAME}\"
