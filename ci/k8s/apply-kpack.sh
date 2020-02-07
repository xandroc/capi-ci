#!/bin/bash

set -eux -o pipefail

touch kubeconfig
export KUBECONFIG="$(pwd)/kubeconfig"

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_DNS_ZONE}" \
  --project="${GOOGLE_PROJECT_NAME}"

gcloud --project="${GOOGLE_PROJECT_NAME}" container clusters get-credentials --zone us-central1-a "${CAPI_ENVIRONMENT_NAME}-cluster"

kubectl apply -f kpack-release/release-*.yaml
