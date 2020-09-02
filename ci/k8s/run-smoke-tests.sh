#!/bin/bash

set -eu -o pipefail

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"


DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)
export SMOKE_TEST_API_ENDPOINT="https://api.${DNS_DOMAIN}"
export SMOKE_TEST_APPS_DOMAIN="apps.${DNS_DOMAIN}"
export SMOKE_TEST_USERNAME=admin
export SMOKE_TEST_PASSWORD=$(cat env-metadata/cf-admin-password.txt)
pushd "cf-for-k8s/tests/smoke"
  ginkgo -progress -v .
popd
