#!/usr/bin/env bash
#
# This file is part of the KubeVirt project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright 2017 Red Hat, Inc.
#

set -e

source hack/common.sh
source hack/config.sh
source hack/version.sh

kubevirt::version::get_version_vars

if [ -z "$1" ]; then
    target="install"
else
    target=$1
    shift
fi

if [ $# -eq 0 ]; then
    args=$binaries
    build_tests="true"
else
    args=$@
fi

PLATFORM=$(uname -m)
case ${PLATFORM} in
x86_64* | i?86_64* | amd64*)
    ARCH="amd64"
    ;;
aarch64* | arm64*)
    ARCH="arm64"
    ;;
*)
    echo "invalid Arch, only support x86_64 and aarch64"
    exit 1
    ;;
esac


dnf install -y dnf-plugins-core && \
dnf config-manager --enable powertools && \
dnf -y install \
    java-11-openjdk-devel \
    libvirt-devel \
    cpio \
    patch \
    make \
    git \
    mercurial \
    sudo \
    gcc \
    gcc-c++ \
    glibc-static \
    libstdc++-static \
    glibc-devel \
    findutils \
    rsync-daemon \
    rsync \
    qemu-img \
    protobuf-compiler \
    python38 \
    python38-devel \
    python38-pip \
    redhat-rpm-config \
    jq \
    wget \
    diffutils --skip-broken && \
dnf -y clean all

ln -s /usr/bin/python3 /usr/bin/python

echo "${KUBEVIRT_GIT_VERSION-}" > /.version


# handle binaries

eval "$(go env)"
BIN_NAME=${target}
OUTPUT_DIR=/usr/bin

if [ "${target}" = "virt-handler" ]; then
    groupadd qemu -g 107
    useradd qemu -g 107 -u 107 -s /bin/bash

    # gen nftables
    mkdir -p /etc/nftables
    cp cmd/virt-handler/ipv4-nat.nft /etc/nftables
    cp cmd/virt-handler/ipv6-nat.nft /etc/nftables

    cp cmd/virt-handler/virt_launcher.cil /

    dnf -y install \
        acl \
        audit-libs \
        basesystem \
        bash \
        bzip2-libs \
        ca-certificates \
        centos-gpg-keys \
        centos-stream-release \
        centos-stream-repos \
        chkconfig \
        coreutils-single \
        cracklib \
        cracklib-dicts \
        crypto-policies \
        curl \
        diffutils \
        elfutils-libelf \
        filesystem \
        findutils \
        gawk \
        glib2 \
        glibc \
        glibc-common \
        glibc-gconv-extra \
        glibc-minimal-langpack \
        gmp \
        gnutls \
        grep \
        gzip \
        info \
        iproute \
        iptables \
        iptables-libs \
        jansson \
        keyutils-libs \
        krb5-libs \
        libacl \
        libaio \
        libarchive \
        libattr \
        libblkid \
        libbpf \
        libburn \
        libcap \
        libcap-ng \
        libcom_err \
        libcurl-minimal \
        libdb \
        libdb-utils \
        libfdisk \
        libffi \
        libgcc \
        libgcrypt \
        libgpg-error \
        libibverbs \
        libidn2 \
        libisoburn \
        libisofs \
        libmnl \
        libmount \
        libnetfilter_conntrack \
        libnfnetlink \
        libnftnl \
        libnghttp2 \
        libnl3 \
        libnsl2 \
        libpcap \
        libpwquality \
        libselinux \
        libselinux-utils \
        libsemanage \
        libsepol \
        libsigsegv \
        libsmartcols \
        libtasn1 \
        libtirpc \
        libunistring \
        libutempter \
        libuuid \
        libverto \
        libxcrypt \
        libxml2 \
        libzstd \
        lua-libs \
        lz4-libs \
        mpfr \
        ncurses-base \
        ncurses-libs \
        nettle \
        nftables \
        openssl-libs \
        p11-kit \
        p11-kit-trust \
        pam \
        pcre \
        pcre2 \
        policycoreutils \
        popt \
        procps-ng \
        qemu-img \
        readline \
        rpm \
        rpm-libs \
        rpm-plugin-selinux \
        sed \
        selinux-policy \
        selinux-policy-targeted \
        setup \
        shadow-utils \
        sqlite-libs \
        systemd-libs \
        tar \
        tzdata \
        util-linux \
        vim-minimal \
        xorriso \
        xz-libs \
        zlib --skip-broken && \
    dnf -y clean all

    cd cmd/container-disk-v2alpha
    # the containerdisk bianry needs to be static, as it runs in a scratch container
    echo "building static binary container-disk"
    gcc -static -o ${OUTPUT_DIR}/container-disk main.c
    cd ../../

    go build -a -o ${OUTPUT_DIR}/virt-chroot cmd/virt-chroot/*.go && chmod +x ${OUTPUT_DIR}/virt-chroot
elif [ "${target}" = "virt-launcher" ]; then
    groupadd qemu -g 107
    useradd qemu -g 107 -u 107 -s /bin/bash

    cp cmd/virt-launcher/node-labeller/node-labeller.sh ${OUTPUT_DIR}
    \cp -rf cmd/virt-launcher/libvirtd.conf /etc/libvirt
    \cp -rf cmd/virt-launcher/qemu.conf /etc/libvirt

    dnf -y install \
        acl \
        audit-libs \
        autogen-libopts \
        basesystem \
        bash \
        bzip2 \
        bzip2-libs \
        ca-certificates \
        centos-gpg-keys \
        centos-stream-release \
        centos-stream-repos \
        chkconfig \
        coreutils-single \
        cracklib \
        cracklib-dicts \
        crypto-policies \
        cryptsetup-libs \
        curl \
        cyrus-sasl \
        cyrus-sasl-gssapi \
        cyrus-sasl-lib \
        daxctl-libs \
        dbus \
        dbus-common \
        dbus-daemon \
        dbus-libs \
        dbus-tools \
        device-mapper \
        device-mapper-libs \
        device-mapper-multipath-libs \
        diffutils \
        dmidecode \
        edk2-ovmf \
        elfutils-default-yama-scope \
        elfutils-libelf \
        elfutils-libs \
        ethtool \
        expat \
        filesystem \
        findutils \
        gawk \
        gettext \
        gettext-libs \
        glib2 \
        glibc \
        glibc-common \
        glibc-gconv-extra \
        glibc-minimal-langpack \
        gmp \
        gnutls \
        gnutls-dane \
        gnutls-utils \
        grep \
        gzip \
        info \
        iproute \
        iproute-tc \
        iptables \
        iptables-libs \
        ipxe-roms-qemu \
        jansson \
        json-c \
        json-glib \
        keyutils-libs \
        kmod \
        kmod-libs \
        krb5-libs \
        libacl \
        libaio \
        libarchive \
        libattr \
        libblkid \
        libbpf \
        libburn \
        libcap \
        libcap-ng \
        libcom_err \
        libcroco \
        libcurl-minimal \
        libdb \
        libdb-utils \
        libevent \
        libfdisk \
        libfdt \
        libffi \
        libgcc \
        libgcrypt \
        libgomp \
        libgpg-error \
        libibverbs \
        libidn2 \
        libisoburn \
        libisofs \
        libmnl \
        libmount \
        libnetfilter_conntrack \
        libnfnetlink \
        libnftnl \
        libnghttp2 \
        libnl3 \
        libnsl2 \
        libpcap- \
        libpmem \
        libpng \
        libpwquality \
        librdmacm \
        libseccomp \
        libselinux \
        libselinux-utils \
        libsemanage \
        libsepol \
        libsigsegv \
        libsmartcols \
        libssh \
        libssh-config \
        libst \
        libtasn1 \
        libtirpc \
        libtpms \
        libunistring \
        libusbx \
        libutempter \
        libuuid \
        libverto \
        libvirt-client \
        libvirt-daemon \
        libvirt-daemon-driver-qemu \
        libvirt-libs \
        libxcrypt \
        libxkbcommon \
        libxml2 \
        libzstd \
        lua-libs \
        lz4-libs \
        lzo \
        lzop \
        mpfr \
        ncurses-base \
        ncurses-libs \
        ndctl-libs \
        nettle \
        nftables \
        nmap-ncat \
        numactl-libs \
        numad \
        openldap \
        openssl-libs \
        p11-kit \
        p11-kit-trust \
        pam \
        pcre \
        pcre2 \
        pixman \
        policycoreutils \
        polkit \
        polkit-libs \
        polkit-pkla-compat \
        popt \
        procps-ng \
        qemu-img- \
        qemu-kvm-common- \
        qemu-kvm-core- \
        qemu-kvm-hw-usbredir- \
        readline \
        rpm \
        rpm-libs \
        rpm-plugin-selinux \
        seabios \
        seabios-bin \
        seavgabios-bin \
        sed \
        selinux-policy \
        selinux-policy-targeted \
        setup \
        sgabios-bin \
        shadow-utils \
        snappy \
        sqlite-libs \
        swtpm \
        swtpm-libs \
        swtpm-tools \
        systemd \
        systemd-container \
        systemd-libs \
        systemd-pam \
        tar \
        tzdata \
        unbound-libs \
        usbredir \
        userspace-rcu \
        util-linux \
        vim-minimal \
        xkeyboard-config \
        xorriso \
        xz \
        xz-libs \
        yajl \
        zlib --skip-broken && \
    dnf -y clean all

    cd cmd/container-disk-v2alpha
    # the containerdisk bianry needs to be static, as it runs in a scratch container
    echo "building static binary container-disk"
    gcc -static -o ${OUTPUT_DIR}/container-disk main.c
    cd ../../

    go build -a -o ${OUTPUT_DIR}/virt-freezer cmd/virt-freezer/main.go && chmod +x ${OUTPUT_DIR}/virt-freezer
    go build -a -o ${OUTPUT_DIR}/virt-probe cmd/virt-probe/virt-probe.go && chmod +x ${OUTPUT_DIR}/virt-probe
elif [ "${target}" = "virt-operator" ]; then
    go build -a -o ${OUTPUT_DIR}/csv-generator tools/csv-generator/csv-generator.go && chmod +x ${OUTPUT_DIR}/csv-generator
fi


# always build and link the binary based on CPU Architecture
LINUX_NAME=${BIN_NAME}-linux-${ARCH}

go vet ./cmd/${target}/...
cd cmd/${target}

echo "building dynamic binary $BIN_NAME"
GOOS=linux GOARCH=${ARCH} go_build -tags selinux -o ${OUTPUT_DIR}/${LINUX_NAME} -ldflags "$(kubevirt::version::ldflags)"

(cd ${OUTPUT_DIR} && ln -sf ${LINUX_NAME} ${BIN_NAME})