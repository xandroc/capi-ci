#!/bin/bash
set -eu

function setup_bosh_env_vars() {
  pushd "bbl-state/${BBL_STATE_DIR}"
    eval "$(bbl print-env)"
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
