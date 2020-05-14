#!/bin/bash

set -eu -o pipefail

function get_image_reference () {
  pushd $1 >/dev/null
    echo "$(cat repository)@$(cat digest)"
  popd >/dev/null
}

function bump_image_references() {
    echo "Updating images..."
    echo "Updating ccng image to: $(get_image_reference capi-docker-image)"
    echo "Updating nginx image to capi-k8s-release digest: $(get_image_reference nginx-docker-image)"
    echo "Updating watcher image to capi-k8s-release digest: $(get_image_reference  watcher-docker-image)"

    cat <<- EOF > "${PWD}/update-images.yml"
---
- type: replace
  path: /images/ccng
  value: $(get_image_reference capi-docker-image)
- type: replace
  path: /images/nginx
  value: $(get_image_reference nginx-docker-image)
- type: replace
  path: /images/capi_kpack_watcher
  value: $(get_image_reference watcher-docker-image)
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

    pushd "capi-k8s-release"
      git config user.name "${GIT_COMMIT_USERNAME}"
      git config user.email "${GIT_COMMIT_EMAIL}"
      git add values/images.yml
      git commit -m "Update image references in values/images.yml"
    popd

    cp -R "capi-k8s-release/." "updated-capi-k8s-release"
}

bump_image_references
make_git_commit
