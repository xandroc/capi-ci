#!/bin/bash
set -eu

# ENV
: "${CF_API_TARGET:?}"
: "${CF_DEPLOYMENT_NAME:=cf}"

CF_ADMIN_USERNAME=admin

pushd "capi-ci-private/${BBL_STATE_DIR}"
  eval "$(bbl print-env)"
  export DIRECTOR_NAME="$(jq -e -r .bosh.directorName bbl-state.json)"
  unset BOSH_ALL_PROXY
popd

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"

CF_ADMIN_PASSWORD="$(credhub get --name=/${DIRECTOR_NAME}/${CF_DEPLOYMENT_NAME}/cf_admin_password -j | jq .value -r)"

echo "Logging in and setting up..."
cf api $CF_API_TARGET --skip-ssl-validation
cf auth admin "$CF_ADMIN_PASSWORD"

echo "Running cats cleanup script"
pushd "capi-workspace/scripts"
  ./cats_cleanup
popd

echo "Success!"
