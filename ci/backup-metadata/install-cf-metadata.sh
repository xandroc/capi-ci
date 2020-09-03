#!/usr/bin/env bash

set -euo pipefail

./ci/ci/backup-metadata/helpers/log-into-gke-cluster.bash

CF_API="https://api.$(yq r cf-install-values/values 'system_domain')"
CF_USERNAME="admin"
CF_PASSWORD=$(yq r cf-install-values/values 'cf_admin_password')

tar -xf tas-cf-metadata-test-artifacts-capi/*.tgz

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
