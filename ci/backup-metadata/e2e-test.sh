#!/usr/bin/env bash
set -euo pipefail

./capi-ci/ci/backup-metadata/helpers/log-into-gke-cluster.bash

pushd ./capi-k8s-release/src/backup-metadata
    make test-e2e
popd
