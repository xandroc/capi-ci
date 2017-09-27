#!/bin/bash

set -eu

# ENV
: "${CLOUD_CONFIG_PATH:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../.." && pwd )"
env_file="${workspace_dir}/environment/metadata"
cloud_config="${workspace_dir}/cloud-config/${CLOUD_CONFIG_PATH}"

BOSH_ENVIRONMENT="$(jq -e -r .target "${env_file}")"
BOSH_CLIENT="$(jq -e -r .client "${env_file}")"
BOSH_CLIENT_SECRET="$(jq -e -r .client_secret "${env_file}")"
BOSH_CA_CERT="$(jq -e -r .ca_cert "${env_file}")"
BOSH_GW_HOST="$(jq -e -r .gw_host "${env_file}")"
export BOSH_ENVIRONMENT BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT BOSH_GW_HOST

bosh -n update-cloud-config "${cloud_config}"
