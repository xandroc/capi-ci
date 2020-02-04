#!/bin/bash

set -eux -o pipefail

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="capi-ci-private/${CAPI_ENVIRONMENT_NAME}/concourse-service-account.json" \
  --project="${GOOGLE_PROJECT_NAME}"

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"

pushd "cf-for-k8s"
  bin/install-cf.sh "${CF_INSTALL_VALUES_FILE}"
popd
