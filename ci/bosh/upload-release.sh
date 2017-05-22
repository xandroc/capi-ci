#!/bin/bash
set -eux

function setup_bosh_env_vars() {
  set +x
  pushd "bbl-state/${BBL_STATE_DIR}"
    export BOSH_CA_CERT="$(bbl director-ca-cert)"
    export BOSH_ENVIRONMENT=$(bbl director-address)
    export BOSH_CLIENT=$(bbl director-username)
    export BOSH_CLIENT_SECRET=$(bbl director-password)
  popd
  set -x
}

function upload_release() {
  for filename in release-tarball/*.tgz; do
    bosh upload-release "$filename"
  done
}

function main() {
  setup_bosh_env_vars
  upload_release
}

main
