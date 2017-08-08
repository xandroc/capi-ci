#!/bin/bash

set -eu

# ENV

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../.." && pwd )"
bbl_vars_file="${workspace_dir}/environment/metadata"
cf_release_dir="${workspace_dir}/cf-release"

# TODO: extract into util script
BOSH_ENVIRONMENT="$(jq -e -r .target "${bbl_vars_file}")"
BOSH_CLIENT="$(jq -e -r .client "${bbl_vars_file}")"
BOSH_CLIENT_SECRET="$(jq -e -r .client_secret "${bbl_vars_file}")"
BOSH_CA_CERT="$(jq -e -r .ca_cert "${bbl_vars_file}")"
BOSH_GW_USER="$(jq -e -r .gw_user "${bbl_vars_file}")"
BOSH_GW_HOST="$(jq -e -r .gw_host "${bbl_vars_file}")"
BOSH_GW_PRIVATE_KEY_CONTENTS="$(jq -e -r .gw_private_key "${bbl_vars_file}")"
export BOSH_ENVIRONMENT BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT \
  BOSH_GW_USER BOSH_GW_HOST BOSH_GW_PRIVATE_KEY_CONTENTS

pushd "${cf_release_dir}/src/capi-release" > /dev/null
  bosh -n create-release --sha2 --force

  bosh -n upload-release --rebase
popd > /dev/null
