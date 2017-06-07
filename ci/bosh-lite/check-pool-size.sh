#!/bin/bash

set -eu

# ENV
: "${MIN_UNCLAIMED_COUNT:?}"
: "${POOL_NAME:="bosh-lites"}"
: "${GIT_USERNAME:="CAPI CI"}"
: "${GIT_EMAIL:="cf-capi-eng+ci@pivotal.io"}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
pool_dir="${workspace_dir}/env-pool"

# OUTPUTS
output_dir="${workspace_dir}/updated-env-pool"

git clone "${pool_dir}" "${output_dir}"

pushd "${output_dir}" > /dev/null
  unclaimed_count="$(find "${POOL_NAME}/unclaimed" -not -path '*/\.*' -type f | wc -l)"
  if [ "${unclaimed_count}" -lt "${MIN_UNCLAIMED_COUNT}" ]; then
    # The create-bosh-lite job watches this file for changes
    date +%s > .trigger-bosh-lites-create

    git config user.name "${GIT_USERNAME}"
    git config user.email "${GIT_EMAIL}"
    git add .trigger-bosh-lites-create
    git commit -m "Not enough unclaimed envs in ${POOL_NAME} pool, updating trigger."
  fi
popd > /dev/null

echo "DONE"
