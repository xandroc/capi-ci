#!/bin/bash

set -eu -o pipefail

MESSAGE_FILE="$(mktemp)"

function get_image_digest_for_resource () {
  pushd $1 >/dev/null
    echo "$(cat digest)"
  popd >/dev/null
}

function git_sha () {
  pushd $1 >/dev/null
    git rev-parse HEAD
  popd >/dev/null
}

CAPI_IMAGE="cloudfoundry/cloud-controller-ng@$(get_image_digest_for_resource capi-docker-image)"
NGINX_IMAGE="cloudfoundry/capi-nginx@$(get_image_digest_for_resource nginx-docker-image)"
WATCHER_IMAGE="cloudfoundry/cf-api-controllers@$(get_image_digest_for_resource cf-api-controllers-docker-image)"
CAPI_SHA="$(git_sha cloud_controller_ng)"
NGINX_SHA="$(git_sha capi-nginx)"
WATCHER_SHA="$(git_sha cf-api-controllers)"

function bump_image_references() {
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
  value: ${WATCHER_IMAGE}
EOF

    pushd "capi-k8s-release"
      bosh interpolate values/images.yml -o "../update-images.yml" > values-int.yml

      echo "#@data/values" > values/images.yml
      echo "---" >> values/images.yml
      cat values-int.yml >> values/images.yml
    popd
}

function make_git_commit() {
    shopt -s dotglob

    cat > "${MESSAGE_FILE}" <<- EOF
images.yml updated by CI
---
Updating ccng image to:
${CAPI_IMAGE}

Built from cloud_controller_ng SHA:
${CAPI_SHA}

---
Updating nginx image to digest:
${NGINX_IMAGE}

Built from capi-k8s-release SHA:
${NGINX_SHA}

---
Updating watcher image to digest:
${WATCHER_IMAGE}

Built from capi-k8s-release SHA:
${WATCHER_SHA}
EOF

    pushd "capi-k8s-release"
      git config user.name "${GIT_COMMIT_USERNAME}"
      git config user.email "${GIT_COMMIT_EMAIL}"
      git add values/images.yml

      # dont make a commit if there aren't new images
      if ! git diff --cached --exit-code; then
        cat "${MESSAGE_FILE}"
        echo "committing!"
        git commit -F "${MESSAGE_FILE}"
      fi
    popd

    cp -R "capi-k8s-release/." "updated-capi-k8s-release"
}

bump_image_references
make_git_commit
