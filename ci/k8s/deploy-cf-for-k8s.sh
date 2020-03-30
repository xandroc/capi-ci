#!/bin/bash

set -eux -o pipefail

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"

export CF_FOR_K8s_DIR="${PWD}/cf-for-k8s"

pushd "capi-k8s-release"
  scripts/bump-cf-for-k8s.sh
popd

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"
pushd "cf-for-k8s"
  hack/generate-values.sh "${CAPI_ENVIRONMENT_NAME}.capi.land" > cf-install-values.yml
  bin/install-cf.sh ./cf-install-values.yml
popd

cp cf-for-k8s/cf-install-values.yml env-metadata/cf-install-values.yml
bosh interpolate --path /cf_admin_password cf-for-k8s/cf-install-values.yml > env-metadata/cf-admin-password.txt
echo "${CAPI_ENVIRONMENT_NAME}.capi.land" > env-metadata/dns-domain.txt

cat > env-metadata/integration_config.json << EOF
{
  "api": "api.${CAPI_ENVIRONMENT_NAME}.capi.land",
  "apps_domain": "${CAPI_ENVIRONMENT_NAME}.capi.land",
  "admin_user": "admin",
  "admin_password": "$(cat env-metadata/cf-admin-password.txt)",
  "skip_ssl_validation": true
}
EOF
