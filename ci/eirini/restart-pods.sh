#!/bin/bash
set -eu

gcloud auth activate-service-account --key-file=<( echo "${GCP_JSON_KEY}" )

gcloud config set project "${GCP_PROJECT_ID}"
gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone "${GCP_ZONE}"
kubectl config current-context

kubectl delete pods -n"${POD_NAMESPACE}" -l name="${POD_NAME_LABEL}"