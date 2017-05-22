#!/bin/bash

set -eu

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../../" && pwd )"
deployment_repo="${workspace_dir}/bosh-deployment"
terraform_dir="${workspace_dir}/terraform"
state_dir="${workspace_dir}/director-state"

pushd "${state_dir}" > /dev/null
  echo -e "\nDestroying the Bosh-Lite..."
  bosh delete-env \
     --state ./state.json \
     --vars-store ./creds.yml \
    ./director.yml

  echo "Done"
popd > /dev/null
