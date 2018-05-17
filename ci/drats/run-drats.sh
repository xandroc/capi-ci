#!/bin/bash
set -eu

# ENV
: "${CF_API_URL:?}"
: "${CF_DEPLOYMENT_NAME:=cf}"
: "${GOPATH:=/go}"
: "${VARS_STORE_PATH:=vars-store.yml}"
: "${CF_ADMIN_USERNAME:=admin}"
: "${SKIP_SUITE_NAME:=""}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
drats_src="${workspace_dir}/drats"
environment_dir="${workspace_dir}/environment"
vars_store_dir="${workspace_dir}/vars-store"

pushd "capi-ci-private/${BBL_STATE_DIR}"
  eval "$(bbl print-env)"
popd

pushd bbr-binary-release
  tar xvf *.tar
  export BBR_BUILD_PATH=`pwd`/releases/bbr
popd

drats_dir="${GOPATH}/src/github.com/cloudfoundry-incubator/disaster-recovery-acceptance-tests"
mkdir -p "${drats_dir}"
cp -a "${drats_src}/." "${drats_dir}"

env_file="${environment_dir}/metadata"
BOSH_ENVIRONMENT="$(jq -e -r .target "${env_file}")"
BOSH_CLIENT="$(jq -e -r .client "${env_file}")"
BOSH_CLIENT_SECRET="$(jq -e -r .client_secret "${env_file}")"
BOSH_CA_CERT="$(jq -e -r .ca_cert "${env_file}")"
BOSH_GW_USER="$(jq -e -r .gw_user "${env_file}")"
BOSH_GW_HOST="$(jq -e -r .gw_host "${env_file}")"
BOSH_GW_PRIVATE_KEY_CONTENTS="$(jq -e -r .gw_private_key "${env_file}")"

JUMPBOX_URL="$(jq -e -r .jumpbox_url "${env_file}")"
JUMPBOX_SSH_KEY="$(jq -e -r .jumpbox_ssh_key "${env_file}")"
JUMPBOX_USERNAME="$(jq -e -r .jumpbox_username "${env_file}")"

export BOSH_ENVIRONMENT BOSH_CLIENT BOSH_CLIENT_SECRET BOSH_CA_CERT \
       JUMPBOX_URL JUMPBOX_SSH_KEY JUMPBOX_USERNAME

CF_ADMIN_PASSWORD="$(bosh interpolate "${vars_store_dir}/${VARS_STORE_PATH}" --path=/cf_admin_password)"
export CF_ADMIN_PASSWORD

tmpdir="$( mktemp -d /tmp/run-drats.XXXXXXXXXX )"

ssh_key="${tmpdir}/bosh.pem"
echo "${BOSH_GW_PRIVATE_KEY_CONTENTS}" > "${ssh_key}"
chmod 600 "${ssh_key}"

ssh_jumpbox_url=$(echo "${JUMPBOX_URL}" | cut -d':' -f1)
sshuttle -e "ssh -i "${JUMPBOX_PRIVATE_KEY}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=600" -r "${JUMPBOX_USERNAME}@${ssh_jumpbox_url}" 10.0.0.0/8 &
tunnel_pid="$!"

cleanup() {
  kill "${tunnel_pid}"
  rm -rf "${tmpdir}"
}
trap 'cleanup' EXIT

if [ -n "${BOSH_CA_CERT}" ]; then
  export BOSH_CERT_PATH="${tmpdir}/bosh.ca"
  echo "${BOSH_CA_CERT}" > "${BOSH_CERT_PATH}"
fi

echo "Running DRATs..."
pushd "${drats_dir}" > /dev/null
  ./scripts/_run_acceptance_tests.sh
popd > /dev/null

echo "Successfully ran DRATs!"
