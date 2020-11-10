#!/usr/bin/env bash
set -euo pipefail

./capi-ci/ci/backup-metadata-generator/helpers/log-into-gke-cluster.bash

pushd ./capi-k8s-release/src/backup-metadata-generator
    make test-e2e
popd
