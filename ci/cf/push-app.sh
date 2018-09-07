#!/bin/bash
set -eu

# ENV
: "${CF_API_URL:?}"
: "${CF_DEPLOYMENT_NAME:=cf}"
: "${APP_NAME:=?}"
: "${APP_ENV_VAR_NAME:=?}"
: "${APP_ENV_VAR_VALUE:=?}"

CF_ADMIN_USERNAME=admin
ORG_NAME=test-key-rotation-org
SPACE_NAME=test-key-rotation-space

pushd "capi-ci-private/${BBL_STATE_DIR}"
  eval "$(bbl print-env)"
  export DIRECTOR_NAME="$(jq -e -r .bosh.directorName bbl-state.json)"
  unset BOSH_ALL_PROXY
popd

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
staticfile_app_dir="${workspace_dir}/staticfile-app"

CF_ADMIN_PASSWORD="$(credhub get --name=/${DIRECTOR_NAME}/${CF_DEPLOYMENT_NAME}/cf_admin_password -j | jq .value -r)"

echo "Logging in and setting up..."
cf api $CF_API_URL --skip-ssl-validation
cf auth admin "$CF_ADMIN_PASSWORD"
cf create-org $ORG_NAME && cf target -o $ORG_NAME
cf create-space $SPACE_NAME && cf target -s $SPACE_NAME

echo "Pushing an app..."
pushd "${staticfile_app_dir}" > /dev/null
  cf push $APP_NAME --no-start
popd > /dev/null

echo "Setting environment variable..."
cf set-env $APP_NAME $APP_ENV_VAR_NAME $APP_ENV_VAR_VALUE

echo "Success!"
