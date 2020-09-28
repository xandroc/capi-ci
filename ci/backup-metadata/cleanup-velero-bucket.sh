#!/usr/bin/env bash

set -euo pipefail

echo "$GKE_SERVICE_ACCOUNT_KEY" > service-account.json

gcloud config set project "$(jq -r .project_id service-account.json)"
gcloud auth activate-service-account --key-file=service-account.json

velero_bucket_name="$(cat velero-bucket/info)"
velero_bucket_url="gs://${velero_bucket_name}"

if gsutil ls "${velero_bucket_url}" >/dev/null 2>&1; then
  gsutil -m rm "${velero_bucket_url}/**"
  gsutil rb "${velero_bucket_url}"
else
  echo
  echo "Velero bucket ${velero_bucket_url} does not exist / has already been cleaned."
  echo "Nothing to clean."
  echo
fi;

