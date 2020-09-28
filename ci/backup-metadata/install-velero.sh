#!/usr/bin/env bash

set -euo pipefail

./ci/ci/backup-metadata/helpers/log-into-gke-cluster.bash

echo "$VELERO_SERVICE_ACCOUNT_KEY" > velero-service-account.json

velero_bucket="$(cat velero-bucket/info)"

velero install \
  --provider gcp \
  --plugins velero/velero-plugin-for-gcp:v1.0.0 \
  --secret-file velero-service-account.json \
  --bucket "${velero_bucket}"

