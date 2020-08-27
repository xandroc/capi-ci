#!/usr/bin/env bash

set -euo pipefail

echo "$GKE_SERVICE_ACCOUNT_KEY" > service-account.json

rand_id=$((1 + RANDOM))
cluster_name="${CLUSTER_PREFIX}-${rand_id}"

gcloud config set project "$(jq -r .project_id service-account.json)"
gcloud auth activate-service-account --key-file=service-account.json
LATEST_GKE_VERSION="$(gcloud container get-server-config --zone europe-west1-b | yq r - 'validMasterVersions[0]')"
gcloud container clusters create "${cluster_name}" --zone=europe-west1-b \
    -m n1-standard-4 \
    --num-nodes=5 \
    --cluster-version="${LATEST_GKE_VERSION}"
gcloud container clusters get-credentials "${cluster_name}" --zone europe-west1-b

echo "${cluster_name}" > cluster-name/info
