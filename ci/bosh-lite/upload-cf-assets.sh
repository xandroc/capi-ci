#!/bin/bash

set -eu

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
cf_deployment_repo="${workspace_dir}/cf-deployment"
env_info="${workspace_dir}/bosh-lite-env-info"

source "${env_info}/metadata"

echo "Uploading stemcell..."
trusty_stemcell_version=$(bosh interpolate --path /stemcells/alias=default/version "${cf_deployment_repo}/cf-deployment.yml")
bosh -n upload-stemcell \
  "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=${trusty_stemcell_version}"

xenial_stemcell_version=$(bosh interpolate --path /path=~1stemcells~1alias=default~1version/value "${cf_deployment_repo}/operations/experimental/use-xenial-stemcell.yml")
bosh -n upload-stemcell \
  "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=${xenial_stemcell_version}"

echo "Uploading cloud-config..."
bosh -n update-cloud-config "${cf_deployment_repo}/iaas-support/bosh-lite/cloud-config.yml"

echo "Done."
