#!/usr/bin/env bash

set -euo pipefail

OM_USERNAME=$(yq read tas-env/pcf.yml 'username')
OM_PASSWORD=$(yq read tas-env/pcf.yml 'password')
OM_API=$(yq read tas-env/pcf.yml 'target')

echo "$TANZU_REGISTRY_CREDENTIALS" > creds_file
REGISTRY_HOSTNAME=$(yq r creds_file hostname)
REGISTRY_USERNAME=$(yq r creds_file username)
REGISTRY_PASSWORD=$(yq r creds_file password)

./ci/ci/backup-metadata/helpers/log-into-gke-cluster.bash


creds=$(om -u "$OM_USERNAME" -t "$OM_API" -p "$OM_PASSWORD" credentials \
  --product-name cf --credential-reference .uaa.admin_credentials -t json)

CF_API="https://api.$(cat tas-env/metadata | jq .sys_domain --raw-output)"
CF_USERNAME=$(echo $creds | jq .identity --raw-output)
CF_PASSWORD=$(echo $creds | jq .password --raw-output)

tar -xf tas-cf-metadata-test-artifacts/*.tgz

mkdir -p installValues
cp backup-metadata/config/values.yml installValues/

pushd installValues
  yq w -i values.yml namespace default
  yq w -i values.yml cf.api $CF_API
  yq w -i values.yml cf.admin_username $CF_USERNAME
  yq w -i values.yml cf.admin_password $CF_PASSWORD
  yq w -i values.yml registry.hostname $REGISTRY_HOSTNAME
  yq w -i values.yml registry.username $REGISTRY_USERNAME
  yq w -i values.yml registry.password $REGISTRY_PASSWORD
  cat values.yml | awk 'NR==1{print; print "---"} NR!=1' | tee values.yml > /dev/null
  echo "CF Credentials: $CF_API $CF_USERNAME $CF_PASSWORD"
popd

pushd backup-metadata
  kapp -y delete -a cf-metadata
  ./bin/install.sh ../installValues
popd
