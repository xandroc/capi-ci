#!/bin/bash

set -eu

# ENV
: "${POOL_NAME:="broken-bosh-lites"}"
: "${GIT_USERNAME:="CAPI CI"}"
: "${GIT_EMAIL:="cf-capi-eng+ci@pivotal.io"}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
pool_dir="${workspace_dir}/env-pool"

pushd "${pool_dir}" > /dev/null
  echo "Searching for bosh-lites..."

  count="$(find "${POOL_NAME}/unclaimed" -not -path '*/\.*' -type f | wc -l)"
  echo "Broken bosh-lites: ${count}"

  if [ "${count}" -gt "0" ]; then
    echo "At least one broken bosh lite exists"
  fi
popd > /dev/null

echo "DONE"
