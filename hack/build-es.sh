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

if [ "${target}" = "install" ]; then
    # Delete all binaries which are not present in the binaries variable to avoid branch inconsistencies
    to_delete=$(comm -23 <(find ${CMD_OUT_DIR} -mindepth 1 -maxdepth 1 -type d | sort) <(echo $binaries | sed -e 's/cmd\///g' -e 's/ /\n/g' | sed -e "s#^#${CMD_OUT_DIR}/#" | sort))
    rm -rf ${to_delete}

    (
        if [ -z "$BIN_NAME" ] || [[ $BIN_NAME == *"container-disk"* ]]; then
            mkdir -p ${CMD_OUT_DIR}/container-disk-v2alpha
            cd cmd/container-disk-v2alpha
            # the containerdisk bianry needs to be static, as it runs in a scratch container
            echo "building static binary container-disk"
            gcc -static -o ${CMD_OUT_DIR}/container-disk-v2alpha/container-disk main.c
        fi
    )
fi


eval "$(go env)"
BIN_NAME=${target}

# always build and link the binary based on CPU Architecture
LINUX_NAME=${BIN_NAME}-linux-${ARCH}

OUTPUT_DIR=/usr/bin

go vet ./cmd/${target}/...
cd ./cmd/${target}

echo "building dynamic binary $BIN_NAME"
GOOS=linux GOARCH=${ARCH} go_build -tags selinux -o ${OUTPUT_DIR}/${LINUX_NAME} -ldflags "$(kubevirt::version::ldflags)"

(cd ${OUTPUT_DIR} && ln -sf ${LINUX_NAME} ${BIN_NAME})