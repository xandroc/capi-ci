#!/bin/bash
set -eu

# ENV
: "${CF_API_URL:?}"
: "${VARS_STORE_PATH:=vars-store.yml}"
: "${CF_ADMIN_USERNAME:=admin}"
: "${APP_NAME:=test-key-rotation-app}"
: "${ORG_NAME:=test-key-rotation-org}"
: "${SPACE_NAME:=test-key-rotation-space}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
vars_store_dir="${workspace_dir}/vars-store"
staticfile_app_dir="${workspace_dir}/staticfile-app"

export CF_ADMIN_PASSWORD="$(bosh interpolate "${vars_store_dir}/${VARS_STORE_PATH}" --path=/cf_admin_password)"

echo "Logging in and setting up..."
cf api $CF_API_URL --skip-ssl-validation
# TODO: remove hardcoded xena cf admin password
cf auth admin u7y17ws09b2ieim18bur #"$CF_ADMIN_PASSWORD"
cf create-org $ORG_NAME && cf target -o $ORG_NAME
cf create-space $SPACE_NAME && cf target -s $SPACE_NAME

echo "Pushing an app..."
pushd "${staticfile_app_dir}" > /dev/null
  cf push $APP_NAME
popd > /dev/null

echo "Setting environment variable..."
cf set-env $APP_NAME $APP_ENV_VAR_NAME $APP_ENV_VAR_VALUE

echo "Success!"
