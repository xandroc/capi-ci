#!/bin/bash

set -eux -o pipefail

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"
hack/generate-values.sh "${CAPI_ENVIRONMENT_NAME}.capi.land" > cf-install-values.yml
pushd "cf-for-k8s"
  bin/install-cf.sh ../cf-install-values.yml
popd
