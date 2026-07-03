# ------------------------------------------------------------
# CUDA Runtime Development Environment
#
# Extends the base development image, but built on top of the
# NVIDIA CUDA runtime image instead of plain Ubuntu (see
# build-base-cuda in the Makefile). Provides CUDA runtime
# libraries for running GPU workloads; no compiler toolchain.
# ------------------------------------------------------------

# Base image to extend. Override at build time, e.g.:
#   docker build --build-arg BASE_IMAGE=learn-dev-base-cuda:custom ...
ARG BASE_IMAGE=learn-dev-base-cuda
FROM ${BASE_IMAGE}
ARG USERNAME=dev

USER root

RUN apt-get update && apt-get install -y     python3     python3-pip \
    python3-venv   nvtop

    
# Pretty terminal
ENV TERM=xterm-256color
    
USER $USERNAME

RUN curl -LsSf https://astral.sh/uv/install.sh | sh