#!/bin/bash

set -eu

# INPUTS

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
environment="$( cat ${workspace_dir}/environment/name )"

# OUTPUTS

destination_dir="${workspace_dir}/destination-directory"

: ${GCP_JSON_KEY:?}
: ${GCP_BUCKET:?}

: ${GCP_PATH:=""}

# TASK
gcloud auth activate-service-account --key-file=<( echo "${GCP_JSON_KEY}" )

pushd "${destination_dir}" > /dev/null
  remote_path="gs://${GCP_BUCKET}/"
  if [ -n "${GCP_PATH}" ]; then
    remote_path="${remote_path}${GCP_PATH}/"
  fi
  remote_path="${remote_path}${environment}"

  gsutil rsync "${remote_path}" .
popd > /dev/null
