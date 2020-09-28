#!/usr/bin/env bash

set -euo pipefail

echo "$GKE_SERVICE_ACCOUNT_KEY" > service-account.json

gcloud config set project "$(jq -r .project_id service-account.json)"
gcloud auth activate-service-account --key-file=service-account.json

rand_id=$((1 + RANDOM))

velero_bucket="ci-velero-bucket-${rand_id}"

gsutil mb "gs://${velero_bucket}"

echo "${velero_bucket}" > velero-bucket/info

echo "Created a bucket: "
cat velero-bucket/info
