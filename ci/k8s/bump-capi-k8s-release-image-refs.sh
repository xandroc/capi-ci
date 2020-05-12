#!/bin/bash

set -eu -o pipefail

# TODO: extract common functions
function get_image_reference () {
  pushd $1 >/dev/null
    echo "$(cat repository)@$(cat digest)"
  popd >/dev/null
}

function bump_image_references() {
    echo "Updating images..."
    echo "Updating ccng image to cloud_controller_ng git SHA: $(cat capi-docker-image/rootfs/cloud_controller_ng/head-tag-file)"
    echo "Updating nginx image to capi-k8s-release git SHA: $(cat capi-docker-image/rootfs/nginx-docker-image/head-tag-file)"
    echo "Updating watcher image to capi-k8s-release git SHA: $(cat capi-docker-image/rootfs/capi_kpack_watcher/head-tag-file)"

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
      bosh interpolate values.yml -o "../update-images.yml" > values-int.yml

      echo "#@data/values" > values.yml
      echo "---" >> values.yml
      cat values-int.yml >> values.yml
    popd
}

function make_git_commit() {
    pushd "capi-k8s-release"
      git add values.yml
      # TODO: figure out changelog for all of the images?
      git commit -m "Update image references in values.yml"
    popd
}

function main() {
    bump_image_references
    make_git_commit
}

main
