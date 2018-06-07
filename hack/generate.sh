#!/bin/bash

set -e

source $(dirname "$0")/common.sh
source $(dirname "$0")/config.sh

find ${KUBEVIRT_DIR}/pkg/ -name "*generated*.go" -exec rm {} -f \;

${KUBEVIRT_DIR}/hack/build-go.sh generate ${WHAT}
/${KUBEVIRT_DIR}/hack/bootstrap-ginkgo.sh
(cd ${KUBEVIRT_DIR}/tools/openapispec/ && go build)
goimports -w -local kubevirt.io ${KUBEVIRT_DIR}/cmd/ ${KUBEVIRT_DIR}/pkg/ ${KUBEVIRT_DIR}/tests/

${KUBEVIRT_DIR}/tools/openapispec/openapispec --dump-api-spec-path ${KUBEVIRT_DIR}/api/openapi-spec/swagger.json

(cd ${KUBEVIRT_DIR}/tools/crd-generator/ && go build)
rm ${KUBEVIRT_DIR}/manifests/generated/*
${KUBEVIRT_DIR}/tools/crd-generator/crd-generator --crd-type=vmi >${KUBEVIRT_DIR}/manifests/generated/vmi-resource.yaml
${KUBEVIRT_DIR}/tools/crd-generator/crd-generator --crd-type=vmirs >${KUBEVIRT_DIR}/manifests/generated/vmirs-resource.yaml
${KUBEVIRT_DIR}/tools/crd-generator/crd-generator --crd-type=vmipreset >${KUBEVIRT_DIR}/manifests/generated/vmipreset-resource.yaml
${KUBEVIRT_DIR}/tools/crd-generator/crd-generator --crd-type=ovm >${KUBEVIRT_DIR}/manifests/generated/ovm-resource.yaml

(cd ${KUBEVIRT_DIR}/tools/vms-generator/ && go build)
${KUBEVIRT_DIR}/tools/vms-generator/vms-generator --generated-vms-dir=${KUBEVIRT_DIR}/cluster/examples
