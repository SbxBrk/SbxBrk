FROM ubuntu:24.04 AS dev
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i "s/^# deb-src/deb-src/g" /etc/apt/sources.list

RUN \
    apt update -y && \
    apt install -y aspell-en bear binutils-gold bison build-essential cm-super \
    cmake curl dvipng fdupes flex fonts-powerline g++ gcc-multilib git gosu htop \
    iproute2 iputils-ping lcov libc++-dev libfdt-dev libglib2.0-dev libgmp-dev \
    libpixman-1-dev libz3-dev linux-tools-generic locales lsb-release lsof libssl-dev libtool \
    ltrace man mercurial nano nasm ncdu neovim ninja-build parallel powerline \
    psmisc python3-pip qpdf ripgrep rr rsync strace sudo texinfo texlive \
    texlive-fonts-recommended texlive-latex-extra tmux tree ubuntu-dbgsym-keyring \
    unzip valgrind virtualenv wget xdot zip zlib1g-dev zsh \
    graphviz-dev libcap-dev tcpflow gnutls-dev tcpdump graphviz-dev jq netcat-traditional \
    elfutils zstd pax-utils dialog apache2-utils python3-tqdm lsb-release wget software-properties-common gnupg

# needed for fuzzilli
RUN \
    wget https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz && \
    tar xzf swift-*-RELEASE-*.tar.gz && \
    cp -r swift-*-RELEASE-*/usr/* /usr && \
    rm -rf swift-*-RELEASE-*;

# swift pulls clang-17, so we remove it and install the one used during eval
RUN cd /tmp && \
    wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 21 && \
    rm llvm.sh && \
    rm -f /usr/bin/clang && \
    rm -f /usr/bin/clang-17 && \ 
    ln -s /usr/bin/clang-21 /usr/bin/clang && \
    ln -s /usr/bin/llvm-config-21 /usr/bin/llvm-config

RUN locale-gen en_US.UTF-8
ARG USER_UID=1000
ARG USER_GID=1000

#Enable sudo group
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
WORKDIR /tmp

RUN update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

#Create group "user" or if there is a group with id USER_GID rename it to user.
RUN groupadd -g ${USER_GID} user || groupmod -g ${USER_GID} -n user $(getent group ${USER_GID} | cut -d: -f1)

#Create user "user" or if there is a use with id USER_UID rename it to user.
# -l -> https://github.com/moby/moby/issues/5419
RUN useradd -l --shell /bin/bash -c "" -m -u ${USER_UID} -g user -G sudo user || usermod -u ${USER_UID} -l user $(id -nu ${USER_UID})

# If we renamed an existing user, we need to make sure that its home directory is updated and owned by us.
RUN mkdir -p /home/user && \
    usermod -d /home/user user && \
    chown -R user:user /home/user

RUN gpasswd -a user user
RUN gpasswd -a user sudo

WORKDIR "/home/user"

RUN echo "set speller \"aspell -x -c\"" > /etc/nanorc

# depot tools needed for v8
RUN cd / && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH="$PATH:/depot_tools"
RUN chown user:user -R /depot_tools

RUN mkdir /work
RUN chown user:user /work

USER user

# install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN mkdir -p /home/user/.config
RUN sudo chown -R user:user /home/user/.config

RUN bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
RUN echo "set disassembly-flavor intel" >> ~/.gdbinit

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --default-toolchain nightly-2024-08-23
ENV PATH="/home/user/.cargo/bin:${PATH}"

RUN cargo install drcov2lcov bindgen-cli
RUN cd /tmp && \
    sh -c "$(wget -O- -4 https://raw.githubusercontent.com/deluan/zsh-in-docker/master/zsh-in-docker.sh)" -- \
    -t agnoster

# Install rr
ENV RR_VERSION=5.8.0
RUN cd /tmp && \
    wget https://github.com/rr-debugger/rr/releases/download/${RR_VERSION}/rr-${RR_VERSION}-Linux-$(uname -m).deb && \
    sudo dpkg -i rr-${RR_VERSION}-Linux-$(uname -m).deb
