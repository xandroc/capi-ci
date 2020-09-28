#/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$PWD

echo "$GKE_SERVICE_ACCOUNT_KEY" > $ROOT_DIR/service-account.json

cluster_name=$(cat $ROOT_DIR/cluster-name/info)
project_name=$(jq -r .project_id $ROOT_DIR/service-account.json)

gcloud auth activate-service-account --key-file=$ROOT_DIR/service-account.json
gcloud container clusters get-credentials "${cluster_name}" --zone europe-west1-b --project "${project_name}"
