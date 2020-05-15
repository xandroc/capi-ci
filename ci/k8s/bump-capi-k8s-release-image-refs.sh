#!/bin/bash

set -eu -o pipefail

MESSAGE_FILE="$(mktemp)"

function image_reference () {
  pushd $1 >/dev/null
    echo "$(cat repository)@$(cat digest)"
  popd >/dev/null
}

function git_sha () {
  pushd $1 >/dev/null
    git rev-parse HEAD
  popd >/dev/null
}

CAPI_IMAGE="$(image_reference capi-docker-image)"
NGINX_IMAGE="$(image_reference nginx-docker-image)"
WATCHER_IMAGE="$(image_reference watcher-docker-image)"
CAPI_SHA="$(git_sha cloud_controller_ng)"
NGINX_SHA="$(git_sha capi-nginx)"
WATCHER_SHA="$(git_sha capi-kpack-watcher)"

function bump_image_references() {
    cat <<- EOF > "${PWD}/update-images.yml"
---
- type: replace
  path: /images/ccng
  value: $(image_reference capi-docker-image)
- type: replace
  path: /images/nginx
  value: $(image_reference nginx-docker-image)
- type: replace
  path: /images/capi_kpack_watcher
  value: $(image_reference watcher-docker-image)
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
