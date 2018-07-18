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
cf api $CF_API_URL --skip-ssl-validation
cf auth admin "$CF_ADMIN_PASSWORD"
cf target -o $ORG_NAME -s $SPACE_NAME

echo "Getting env variables for app..."
value=$(cf env $APP_NAME | grep $APP_ENV_VAR_NAME | cut -d' ' -f2)

if [ $value = $APP_ENV_VAR_VALUE ]; then
  echo "Success!"
else
  echo "Set env $APP_ENV_VAR_NAME to $APP_ENV_VAR_VALUE, but got $value"
  exit 1
fi
