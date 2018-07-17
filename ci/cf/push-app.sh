#!/bin/bash
set -eu

# ENV
: "${CF_API_URL:?}"
: "${APP_NAME:=?}"
: "${APP_ENV_VAR_NAME:=?}"
: "${APP_ENV_VAR_VALUE:=?}"

VARS_STORE_PATH=vars-store.yml
CF_ADMIN_USERNAME=admin
ORG_NAME=test-key-rotation-org
SPACE_NAME=test-key-rotation-space

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
vars_store_dir="${workspace_dir}/vars-store"
staticfile_app_dir="${workspace_dir}/staticfile-app"

CF_ADMIN_PASSWORD="$(bosh interpolate "${vars_store_dir}/${VARS_STORE_PATH}" --path=/cf_admin_password)"

echo "Logging in and setting up..."
cf login -a $CF_API_URL -u admin -p "$CF_ADMIN_PASSWORD" --skip-ssl-validation
cf create-org $ORG_NAME && cf target -o $ORG_NAME
cf create-space $SPACE_NAME && cf target -s $SPACE_NAME

echo "Pushing an app..."
pushd "${staticfile_app_dir}" > /dev/null
  cf push $APP_NAME --no-start
popd > /dev/null

echo "Setting environment variable..."
cf set-env $APP_NAME $APP_ENV_VAR_NAME $APP_ENV_VAR_VALUE

echo "Success!"
