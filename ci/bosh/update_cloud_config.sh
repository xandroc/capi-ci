#!/bin/bash

set -eu

# ENV
: "${CLOUD_CONFIG_PATH:?}"

# INPUTS
pushd "bbl-state/${BBL_STATE_DIR}"
  eval "$(bbl print-env)"
popd

workspace_dir="$( cd "${script_dir}/../../.." && pwd )"
cloud_config="${workspace_dir}/cloud-config/${CLOUD_CONFIG_PATH}"

bosh -n update-cloud-config "${cloud_config}"
