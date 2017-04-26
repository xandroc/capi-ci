#!/bin/bash

set -eu

# INPUTS

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../../" && pwd )"
environment="$( cat "${workspace_dir}/environment/name" )"

: ${GCP_JSON_KEY:?}
: ${GCP_BUCKET:?}

: ${GCP_PATH:=""}

# TASK
gcloud auth activate-service-account --key-file=<( echo "${GCP_JSON_KEY}" )

remote_path="gs://${GCP_BUCKET}/"
if [ -n "${GCP_PATH}" ]; then
  remote_path="${remote_path}${GCP_PATH}/"
fi
remote_path="${remote_path}${environment}"
gsutil rm -r "${remote_path}"
