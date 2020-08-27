#!/usr/bin/env bash

set -euo pipefail

echo "$GKE_SERVICE_ACCOUNT_KEY" > service-account.json

gcloud config set project "$(jq -r .project_id service-account.json)"
gcloud auth activate-service-account --key-file=service-account.json

cluster_name="$(cat cluster-name/info)"

if gcloud container clusters describe --zone=europe-west1-b "${cluster_name}" >/dev/null 2>&1; then
  gcloud container clusters delete --quiet --zone=europe-west1-b "${cluster_name}"
else
  echo
  echo "Cluster ${cluster_name} does not exist / has already been cleaned."
  echo "Nothing to clean."
  echo
fi;
