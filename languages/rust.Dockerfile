# ------------------------------------------------------------
# Rust Development Environment
#
# Extends the base development image and installs Rust using
# rustup (official installer).
# ------------------------------------------------------------

# Base image to extend. Override at build time, e.g.:
#   docker build --build-arg BASE_IMAGE=learn-dev-base:custom ...
ARG BASE_IMAGE=learn-dev-base
FROM ${BASE_IMAGE}
ARG USERNAME=dev

USER $USERNAME

# Install Rust toolchain
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# Add Cargo binaries to PATH
ENV PATH="/home/dev/.cargo/bin:${PATH}"

# Pretty terminal
ENV TERM=xterm-256color

