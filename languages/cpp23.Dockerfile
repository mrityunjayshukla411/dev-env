# ------------------------------------------------------------
# C++ Development Environment (C++23)
#
# Installs modern GCC 15 toolchain + essential tools
# on top of the base dev image.
# ------------------------------------------------------------

FROM learn-dev-base
ARG USERNAME=dev

USER root

# ---- Install GCC 15 toolchain (via Ubuntu toolchain PPA) ----
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && apt-get install -y \
        gcc-15 g++-15 \
        cmake \
        ninja-build \
        gdb \
        cgdb \
        valgrind \
        && rm -rf /var/lib/apt/lists/*

# ---- Set GCC 15 as default ----
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 100


# ---- Dev UX ----
# Pretty terminal
ENV TERM=xterm-256color

RUN echo "source /usr/share/bash-completion/bash_completion" >> /home/ubuntu/.bashrc && \
    echo "alias ll='ls -alF'" >> /home/ubuntu/.bashrc && \
    echo "alias b='cmake -B build -G Ninja && cmake --build build'" >> /home/ubuntu/.bashrc && \
    echo "alias r='cmake --build build --target'" >> /home/ubuntu/.bashrc 


USER $USERNAME
RUN echo 'colorscheme murphy' >> /home/ubuntu/.vimrc
