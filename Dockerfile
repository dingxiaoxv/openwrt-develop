# Official ImmortalWrt openwrt-24.10 recommended build environment.
# Debian 11 is the distribution preferred by the upstream README.
FROM debian:11-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILDER_UID=1000
ARG BUILDER_GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
        bzip2 ca-certificates ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex \
        gawk gettext gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool \
        lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev \
        libmpfr-dev libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev \
        libz-dev lld llvm lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf \
        python3 python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c \
        rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto \
        xxd zlib1g-dev zstd \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${BUILDER_GID}" builder \
    && useradd --uid "${BUILDER_UID}" --gid "${BUILDER_GID}" --create-home --shell /bin/bash builder \
    && mkdir -p /workspace /ccache \
    && chown -R builder:builder /workspace /ccache

ENV CCACHE_DIR=/ccache \
    CCACHE_COMPRESS=1 \
    CCACHE_MAXSIZE=20G \
    FORCE_UNSAFE_CONFIGURE=1

WORKDIR /workspace
USER builder

CMD ["bash"]
