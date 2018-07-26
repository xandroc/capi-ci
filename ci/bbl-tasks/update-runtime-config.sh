#!/bin/bash
set -eu

# ENV
: "${RUNTIME_CONFIG_NAME:?}"
: "${RUNTIME_CONFIG_PATH:?}"

function setup_bosh_env_vars() {
  echo "Setting env vars..."
  pushd "bbl-state/${BBL_STATE_DIR}"
    eval "$(bbl print-env)"
  popd
}

function update_bosh_runtime_config() {
  echo "Updating bosh runtime config on ${BOSH_ENVIRONMENT}..."
  pushd "bbl-state/${BBL_STATE_DIR}"
    bosh -n update-runtime-config \
    ${RUNTIME_CONFIG_PATH} \
    --name=${RUNTIME_CONFIG_NAME}
  popd
}

function main() {
  setup_bosh_env_vars
  update_bosh_runtime_config
  echo "Done"
}

main
