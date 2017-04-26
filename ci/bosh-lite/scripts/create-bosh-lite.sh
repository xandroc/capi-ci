#!/bin/bash

set -eu

# ENV
: "${GCP_JSON_KEY:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../../" && pwd )"
deployment_repo="${workspace_dir}/bosh-deployment"
terraform_dir="${workspace_dir}/terraform"

# OUTPUTS
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

    echo -e "\nDeploying new Bosh-Lite..."
    env_name="$( cat "${terraform_dir}/name" )"
    bosh create-env \
       --state ./state.json \
       --vars-store ./creds.yml \
      ./director.yml

    director_ip=$(bosh interpolate --path /external_ip "${terraform_dir}/metadata")
    echo -e "\nUploading stemcell..."
    bosh -e "${director_ip}" \
      --client admin \
      --client-secret="$( bosh interpolate --path /admin_password ./creds.yml )" \
      --ca-cert="$( bosh interpolate --path /default_ca/ca ./creds.yml )" \
      upload-stemcell \
      https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
popd > /dev/null
