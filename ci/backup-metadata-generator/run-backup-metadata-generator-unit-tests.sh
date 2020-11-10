#!/bin/bash

set -eu

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"

pushd "${workspace_dir}/backup-metadata-generator/src/backup-metadata-generator" >/dev/null
    make test-unit
popd >/dev/null
