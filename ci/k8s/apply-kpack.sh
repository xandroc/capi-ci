#!/bin/bash

set -eux -o pipefail

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"

KUBECONFIG="capi-ci-private/${CAPI_ENVIRONMENT_NAME}/kubeconfig" kubectl apply -f "${KUBECTL_YAML_FILE}"
