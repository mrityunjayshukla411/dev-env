# ------------------------------------------------------------
# Rust Development Environment
#
# Extends the base development image and installs Rust using
# rustup (official installer).
# ------------------------------------------------------------

FROM learn-dev-base

USER ubuntu

# Install Rust toolchain
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# Add Cargo binaries to PATH
ENV PATH="/home/dev/.cargo/bin:${PATH}"
