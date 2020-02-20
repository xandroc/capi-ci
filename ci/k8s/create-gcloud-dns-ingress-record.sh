#!/usr/bin/env bash

set -eux -o pipefail

gcloud auth activate-service-account \
  "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
  --key-file="${GOOGLE_KEY_FILE_PATH}" \
  --project="${GOOGLE_PROJECT_NAME}"

source "capi-ci-private/${CAPI_ENVIRONMENT_NAME}/.envrc"

NAME="*.${CF_DOMAIN}."
INGRESS_IP="$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}')"
DNS_TTL=15

set +e
PREVIOUS_RECORD_IP="$(gcloud dns record-sets list --zone ${GOOGLE_DNS_ZONE} | grep ${NAME} | awk '{ print $4 }')"
set -e

gcloud dns record-sets transaction start --zone="${GOOGLE_DNS_ZONE}"

if [[ -n "${PREVIOUS_RECORD_IP}" ]]; then
  gcloud dns record-sets transaction remove "${PREVIOUS_RECORD_IP}" --name "${NAME}" --ttl="${DNS_TTL}" --type=A --zone="${GOOGLE_DNS_ZONE}"
fi

gcloud dns record-sets transaction add "${INGRESS_IP}" --name "${NAME}" --ttl="${DNS_TTL}" --type=A --zone="${GOOGLE_DNS_ZONE}"

gcloud dns record-sets transaction execute --zone="${GOOGLE_DNS_ZONE}"

sleep "${DNS_TTL}"
