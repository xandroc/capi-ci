#!/bin/bash

set -eu

# ENV
: "${GCP_JSON_KEY:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../../" && pwd )"
deployment_repo="${workspace_dir}/bosh-deployment"
terraform_dir="${workspace_dir}/terraform"
state_dir="${workspace_dir}/director-state"

pushd "${state_dir}" > /dev/null
  bosh interpolate "${deployment_repo}/bosh.yml" \
    -o "${deployment_repo}/gcp/cpi.yml" \
    -o "${deployment_repo}/bosh-lite.yml" \
    -o "${deployment_repo}/bosh-lite-runc.yml" \
    -o "${deployment_repo}/gcp/bosh-lite-vm-type.yml" \
    -o "${deployment_repo}/jumpbox-user.yml" \
    -o "${deployment_repo}/external-ip-not-recommended.yml" \
    -v director_name="Bosh Lite Director" \
    -v gcp_credentials_json="'${GCP_JSON_KEY}'" \
    -l "${terraform_dir}/metadata" \
    > ./director.yml

    echo -e "\nDestroying the Bosh-Lite..."
    bosh delete-env \
       --state ./state.json \
       --vars-store ./creds.yml \
      ./director.yml

    echo "Done"
popd > /dev/null
