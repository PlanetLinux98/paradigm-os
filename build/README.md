# build/

Build tooling for producing the ParadigmOS ISO.

## How it works

`build-iso.sh` runs `livemedia-creator --no-virt` (from `lorax-lmc-novirt`)
against [`kickstart/paradigmos.ks`](../kickstart/paradigmos.ks) inside an
official `fedora:44` container. On the maintainer's machine that container runs
under Docker Engine inside WSL2 (Ubuntu 24.04).

```bash
# from the repo root, inside WSL2
bash build/build-iso.sh
```

Output (ISO + logs) lands in `build/output/`, which is gitignored.

## Notes

- The container needs `--privileged` because `--no-virt` loop-mounts the image
  and runs Anaconda directly.
- The kickstart is self-contained (no `%include`), so no `ksflatten` step.
- Known-open items before the first ISO is considered "real" are tracked as
  `TODO(...)` markers inside the kickstart: NVIDIA driver strategy, Anaconda
  branding hooks, GNOME theme, Plymouth splash, snapshot tooling, and packaging
  the wallpapers as an RPM instead of fetching them at build time.
