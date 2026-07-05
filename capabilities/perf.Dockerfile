# ------------------------------------------------------------
# perf capability
#
# Layers Linux `perf` profiling tools on top of any base image.
# Composable: any environment can build through this stage to
# opt in, without the language Dockerfiles knowing it exists.
#
# Requires the container to be run with the PERFMON capability
# (see docker-compose.perf.yml) and a host with
# kernel.perf_event_paranoid set low enough to allow profiling.
#
# perf's wrapper script refuses to run a binary that doesn't match
# the running kernel's exact version (`uname -r`), and the shared
# libraries it links against differ per Ubuntu release, so a
# generic package is unreliable across container/host combos.
# KERNEL_RELEASE (threaded from `uname -r` in the Makefile) lets us
# install the exact matching package straight from apt when it's
# available, which resolves both problems at once.
# ------------------------------------------------------------

ARG BASE_IMAGE=learn-dev-base
FROM ${BASE_IMAGE}
ARG USERNAME=dev
ARG KERNEL_RELEASE

USER root

RUN apt-get update && \
    if [ -n "$KERNEL_RELEASE" ] && apt-cache show "linux-tools-$KERNEL_RELEASE" >/dev/null 2>&1; then \
        apt-get install -y "linux-tools-$KERNEL_RELEASE"; \
    else \
        apt-get install -y linux-tools-generic; \
    fi && \
    rm -rf /var/lib/apt/lists/*

USER $USERNAME
