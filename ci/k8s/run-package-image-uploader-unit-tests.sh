#!/bin/bash

set -eu

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"

go install github.com/onsi/ginkgo/ginkgo
pushd "${workspace_dir}/package-image-uploader/src/package-image-uploader" >/dev/null
     ginkgo -r -keepGoing -p -trace -randomizeAllSpecs -progress --race
popd >/dev/null
