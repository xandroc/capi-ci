#!/bin/bash
set -eu

function setup_bosh_env_vars() {
  pushd "bbl-state/${BBL_STATE_DIR}"
    bblver="$(bbl -v | cut -d' ' -f2 | cut -d'.' -f1)"
    if [ $bblver -eq "6" ]; then
      eval "$(bbl print-env)"
    else
      export BOSH_CA_CERT="$(bbl director-ca-cert)"
      export BOSH_ENVIRONMENT=$(bbl director-address)
      export BOSH_CLIENT=$(bbl director-username)
      export BOSH_CLIENT_SECRET=$(bbl director-password)
    fi
  popd
}

function upload_stemcell() {
  bosh upload-stemcell --sha2 https://bosh.io/d/stemcells/bosh-google-kvm-windows2012R2-go_agent
}

function main() {
  setup_bosh_env_vars
  upload_stemcell
}

main
