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


# handle binaries

eval "$(go env)"
BIN_NAME=${target}
OUTPUT_DIR=/usr/bin

if [ "${target}" = "virt-handler" ]; then
    # gen nftables
    mkdir -p /etc/nftables
    cp cmd/virt-handler/ipv4-nat.nft /etc/nftables
    cp cmd/virt-handler/ipv6-nat.nft /etc/nftables

    cd cmd/container-disk-v2alpha
    # the containerdisk bianry needs to be static, as it runs in a scratch container
    echo "building static binary container-disk"
    gcc -static -o ${OUTPUT_DIR}/container-disk main.c
    cd ../../

    go build -a -o ${OUTPUT_DIR}/virt-chroot cmd/virt-chroot/*.go && chmod +x ${OUTPUT_DIR}/virt-chroot
elif [ "${target}" = "virt-launcher" ]; then
    cp cmd/virt-launcher/node-labeller/node-labeller.sh ${OUTPUT_DIR}
    cp -i cmd/virt-launcher/libvirtd.conf /etc/libvirt
    cp -i cmd/virt-launcher/qemu.conf /etc/libvirt

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