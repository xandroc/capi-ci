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

function upload_stemcell() {
  # bosh upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-windows2012R2-go_agent
  bosh upload-stemcell 'https://s3.amazonaws.com/bosh-windows-stemcells-release-candidates/light-bosh-stemcell-1093.0.0-build.1-google-kvm-windows2012R2-go_agent.tgz'
}

function main() {
  setup_bosh_env_vars
  upload_stemcell
}

main
