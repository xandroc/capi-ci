#!/bin/bash

set -eu

# INPUTS

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../../" && pwd )"
source_dir="${workspace_dir}/source-directory"

: ${FILE_NAMES:?}
: ${AWS_ACCESS_KEY_ID:?}
: ${AWS_SECRET_ACCESS_KEY:?}
: ${AWS_ENDPOINT:?}
: ${S3_BUCKET:?}

: ${S3_PATH:=""}
: ${AWS_DEFAULT_REGION:=""}

# TASK
pushd "${source_dir}" > /dev/null
  for filename in ${FILE_NAMES}; do
    aws --endpoint-url "${AWS_ENDPOINT}" s3 cp "$filename" s3://${S3_BUCKET}/${S3_PATH}/
  done
popd > /dev/null
