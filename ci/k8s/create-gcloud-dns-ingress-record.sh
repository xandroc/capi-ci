#!/usr/bin/env bash

set -eux -o pipefail

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"

# TODO: kubectl get that ingress
INGRESS_IP="$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}')"

gcloud dns record-sets transaction start --zone="${GOOGLE_DNS_ZONE}"

gcloud dns record-sets transaction add "${INGRESS_IP}" --name=\*."${CF_DOMAIN}". --ttl=300 --type=A --zone="${GOOGLE_DNS_ZONE}"

gcloud dns record-sets transaction remove "${INGRESS_IP}" --name=\*."${CF_DOMAIN}". --ttl=300 --type=A --zone="${GOOGLE_DNS_ZONE}"

gcloud dns record-sets transaction execute --zone="${GOOGLE_DNS_ZONE}"
