#!/bin/bash

set -eu -o pipefail

export CF_FOR_K8s_DIR="${PWD}/cf-for-k8s"
export SERVICE_ACCOUNT_KEY="${PWD}/${GOOGLE_KEY_FILE_PATH}"

function get_image_digest_for_resource () {
  pushd $1 >/dev/null
    echo "$(cat digest)"
  popd >/dev/null
}

# actual script

CAPI_IMAGE="cloudfoundry/cloud-controller-ng@$(get_image_digest_for_resource capi-docker-image)"
NGINX_IMAGE="cloudfoundry/capi-nginx@$(get_image_digest_for_resource nginx-docker-image)"
CONTROLLERS_IMAGE="cloudfoundry/cf-api-controllers@$(get_image_digest_for_resource cf-api-controllers-docker-image)"
PACKAGE_IMAGE_UPLOADER_IMAGE="cloudfoundry/cf-api-package-image-uploader@$(get_image_digest_for_resource package-image-uploader-docker-image)"

echo "kapp version..."
kapp version

echo "Logging into gcloud..."
gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"

echo "Updating images..."
echo "Updating ccng image to cloud_controller_ng digest: ${CAPI_IMAGE}"
echo "Updating nginx image to capi-k8s-release digest: ${NGINX_IMAGE}"
echo "Updating cf-api-controllers image to capi-k8s-release digest: ${CONTROLLERS_IMAGE}"
echo "Updating package image uploader image to capi-k8s-release digest: ${PACKAGE_IMAGE_UPLOADER_IMAGE}"

cat <<- EOF > "${PWD}/update-images.yml"
---
- type: replace
  path: /images/ccng
  value: ${CAPI_IMAGE}
- type: replace
  path: /images/nginx
  value: ${NGINX_IMAGE}
- type: replace
  path: /images/cf_api_controllers
  value: ${CONTROLLERS_IMAGE}
- type: replace
  path: /images/package_image_uploader
  value: ${PACKAGE_IMAGE_UPLOADER_IMAGE}
EOF

pushd "capi-k8s-release"
  bosh interpolate values/images.yml -o "../update-images.yml" > values-int.yml

  echo "#@data/values" > values/images.yml
  echo "---" >> values/images.yml
  cat values-int.yml >> values/images.yml

  scripts/bump-cf-for-k8s.sh
popd

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"
cp -r "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/." env-metadata/

pushd "cf-for-k8s"
  # hack/generate-values.sh -d "${CAPI_ENVIRONMENT_NAME}.capi.land" -g "${SERVICE_ACCOUNT_KEY}" > env-metadata/cf-install-values.yml

  lb_static_ip="$(jq -r .lb_static_ip ../cluster-tf-state/metadata)"
  kapp deploy -a cf -f <(ytt -f ./config/ -f ../env-metadata/cf-install-values.yml -v istio_static_ip="${lb_static_ip}") -y
popd

# cp cf-for-k8s/cf-install-values.yml env-metadata/cf-install-values.yml
bosh interpolate --path /cf_admin_password env-metadata/cf-install-values.yml > env-metadata/cf-admin-password.txt
echo "${CAPI_ENVIRONMENT_NAME}.capi.land" > env-metadata/dns-domain.txt

cat > env-metadata/integration_config.json << EOF
{
  "api": "api.${CAPI_ENVIRONMENT_NAME}.capi.land",
  "apps_domain": "apps.${CAPI_ENVIRONMENT_NAME}.capi.land",
  "admin_user": "admin",
  "admin_password": "$(cat env-metadata/cf-admin-password.txt)",
  "skip_ssl_validation": true,
  "include_kpack": true,
  "gcloud_project_name": "${GOOGLE_PROJECT_NAME}",
  "cluster_zone": "${GCP_ZONE}",
  "cluster_name": "${CLUSTER_NAME}",
  "cf_push_timeout": 480
}
EOF
