#!/usr/bin/env bash
set -euo pipefail

./ci/ci/backup-metadata/helpers/log-into-gke-cluster.bash

pushd ./capi-k8s-release/backup-metadata
    make test-e2e
popd
