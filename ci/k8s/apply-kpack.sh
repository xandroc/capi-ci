#!/bin/bash

set -eux -o pipefail

touch kubeconfig
export KUBECONFIG="$(pwd)/kubeconfig"

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="capi-ci-private/${CAPI_ENVIRONMENT_NAME}/concourse-service-account.json" \
  --project="${GOOGLE_PROJECT_NAME}"

gcloud --project=cf-capi-arya container clusters get-credentials --zone us-central1-a samus-cluster

kubectl apply -f "${KUBECTL_YAML_FILE}"
