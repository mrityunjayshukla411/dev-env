# ------------------------------------------------------------
# Go Development Environment
#
# Installs Go toolchain on top of the base dev image.
# ------------------------------------------------------------

FROM learn-dev-base

USER root

# Remove any older versions of go 
RUN rm -rf /usr/local/go
# Download and install Go
RUN wget https://go.dev/dl/go1.26.1.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.26.1.linux-amd64.tar.gz && rm go1.26.1.linux-amd64.tar.gz 

RUN echo "source /usr/share/bash-completion/bash_completion" >> /home/ubuntu/.bashrc

ENV PATH="/usr/local/go/bin:${PATH}"

USER ubuntu
