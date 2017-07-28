#!/bin/bash
set -eu

function setup_bosh_env_vars() {
  pushd "bbl-state/${BBL_STATE_DIR}"
    export BOSH_CA_CERT="$(bbl director-ca-cert)"
    export BOSH_ENVIRONMENT=$(bbl director-address)
    export BOSH_CLIENT=$(bbl director-username)
    export BOSH_CLIENT_SECRET=$(bbl director-password)
  popd
}

function upload_release() {
  for filename in release-tarball/*.tgz; do
    bosh2 upload-release --sha2 "$filename"
  done
}

function main() {
  setup_bosh_env_vars
  upload_release
}

main
