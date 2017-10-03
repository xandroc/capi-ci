#!/bin/bash
set -eu

function setup_bosh_env_vars() {
  echo "Setting env vars..."
  pushd "bbl-state/${BBL_STATE_DIR}"
    export BOSH_CA_CERT="$(bbl director-ca-cert)"
    export BOSH_ENVIRONMENT=$(bbl director-address)
    export BOSH_CLIENT=$(bbl director-username)
    export BOSH_CLIENT_SECRET=$(bbl director-password)
  popd
}

function update_bosh_cloud_config() {
  echo "Updating bosh cloud-config on ${BOSH_ENVIRONMENT}..."
  pushd "bbl-state/${BBL_STATE_DIR}"
    bosh -n update-cloud-config <(bbl cloud-config) \
      -o ../../capi-ci/cf-deployment-operations/temporary/credhub-lb-cloud-properties.yml
  popd
}

function main() {
  setup_bosh_env_vars
  update_bosh_cloud_config
  echo "Done"
}

main
