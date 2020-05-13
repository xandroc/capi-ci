#!/bin/bash

set -eu -o pipefail

export CF_FOR_K8s_DIR="${PWD}/cf-for-k8s"
export SERVICE_ACCOUNT_KEY="${PWD}/${GOOGLE_KEY_FILE_PATH}"

function getImageReference () {
  pushd $1 >/dev/null
    echo "$(cat repository)@$(cat digest)"
  popd >/dev/null
}

# TODO: get rid of the following after this is merged: https://github.com/cloudfoundry/cf-for-k8s/pull/192
function temp_update_vendir_definition() {
  cat <<- EOF > "${PWD}/update-vendir-def.yml"
---
- type: replace
  path: /directories/path=config~1_ytt_lib/contents/path=github.com~1cloudfoundry~1capi-k8s-release/includePaths
  value: ["templates/**/*", "values/**/*"]
EOF

  bosh interpolate cf-for-k8s/vendir.yml -o "${PWD}/update-vendir-def.yml" > updated-vendir.yml
  cat updated-vendir.yml > cf-for-k8s/vendir.yml

  pushd cf-for-k8s
    vendir sync
  popd
}

echo "Logging into gcloud..."
gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"

echo "Updating images..."
echo "Updating ccng image to cloud_controller_ng digest: $(cat capi-docker-image/digest)"
echo "Updating nginx image to capi-k8s-release digest: $(cat capi-docker-image/digest)"
echo "Updating watcher image to capi-k8s-release digest: $(cat capi-docker-image/digest)"

cat <<- EOF > "${PWD}/update-images.yml"
---
- type: replace
  path: /images/ccng
  value: $(getImageReference capi-docker-image)
- type: replace
  path: /images/nginx
  value: $(getImageReference nginx-docker-image)
- type: replace
  path: /images/capi_kpack_watcher
  value: $(getImageReference watcher-docker-image)
EOF

temp_update_vendir_definition

pushd "capi-k8s-release"
  bosh interpolate values/images.yml -o "../update-images.yml" > values-int.yml

  echo "#@data/values" > values/images.yml
  echo "---" >> values/images.yml
  cat values-int.yml >> values/images.yml

  scripts/bump-cf-for-k8s.sh
popd

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"
pushd "cf-for-k8s"
  hack/generate-values.sh -d "${CAPI_ENVIRONMENT_NAME}.capi.land" -g "${SERVICE_ACCOUNT_KEY}" > cf-install-values.yml

  kapp deploy -a cf -f <(ytt -f ./config/ -f ./cf-install-values.yml) -y
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
  "skip_ssl_validation": true,
  "include_kpack": true,
  "gcloud_project_name": "${GOOGLE_PROJECT_NAME}",
  "cluster_zone": "${GCP_ZONE}",
  "cluster_name": "${CLUSTER_NAME}"
}
EOF
