# build/

Build tooling for producing the ParadigmOS ISO.

The build runs `livemedia-creator`/`lorax` against the kickstart files in
`kickstart/`, inside an official `fedora` container, driven from Docker running
in WSL2 (Ubuntu 24.04) on the maintainer's machine. Dockerfile and build script
land here alongside the first working kickstart file.
