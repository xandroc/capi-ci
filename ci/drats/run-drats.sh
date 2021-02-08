#!/bin/bash
set -eu

# ENV
: "${CF_API_URL:?}"
: "${CF_DEPLOYMENT_NAME:=cf}"
: "${GOPATH:=/go}"
: "${CF_ADMIN_USERNAME:=admin}"
: "${SKIP_SUITE_NAME:=""}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
drats_src="${workspace_dir}/drats"

tmpdir="$( mktemp -d /tmp/run-drats.XXXXXXXXXX )"
ssh_key="${tmpdir}/bosh.pem"

pushd "capi-ci-private/${BBL_STATE_DIR}"
  eval "$(bbl print-env)"
  export DIRECTOR_NAME="$(jq -e -r .bosh.directorName bbl-state.json)"
  unset BOSH_ALL_PROXY

  bbl ssh-key > "${ssh_key}"
  chmod 600 "${ssh_key}"
  ssh_jumpbox_url=$(bbl jumpbox-address)
popd

pushd bbr-binary-release
  tar xvf *.tar
  export BBR_BUILD_PATH=$(pwd)/releases/bbr
popd

drats_dir="${GOPATH}/src/github.com/cloudfoundry-incubator/disaster-recovery-acceptance-tests"
mkdir -p "${drats_dir}"
cp -a "${drats_src}/." "${drats_dir}"

CF_ADMIN_PASSWORD="$(credhub get --name=/${DIRECTOR_NAME}/${CF_DEPLOYMENT_NAME}/cf_admin_password -j | jq .value -r)"
echo ${DIRECTOR_NAME}
echo ${CF_DEPLOYMENT_NAME}
echo ${CF_ADMIN_PASSWORD}
export CF_ADMIN_PASSWORD

sshuttle -e "ssh -i "${JUMPBOX_PRIVATE_KEY}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=600" -r "jumpbox@${ssh_jumpbox_url}" 10.0.0.0/8 &
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
