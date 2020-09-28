#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$PWD

cluster_name=$(cat $ROOT_DIR/cluster-name/info)
dns_domain="${cluster_name}.${DNS_ROOT_DOMAIN}"

# temporary hack
wget -O- https://k14s.io/install.sh | bash

./ci/ci/backup-metadata/helpers/log-into-gke-cluster.bash

kapp delete -a cf -y

pushd cf-for-k8s
  echo "Generating install values..."
  ./hack/generate-values.sh --cf-domain "${dns_domain}" --gcr-service-account-json $ROOT_DIR/service-account.json > cf-install-values.yml

  echo "Installing CF..."
  kapp deploy -a cf -f <(ytt -f config -f cf-install-values.yml) -y

  echo "Configuring DNS..."
  gcloud config set project "$(jq -r .project_id $ROOT_DIR/service-account.json)"
  ../ci/ci/backup-metadata/update-gcp-dns.sh "${dns_domain}" "${DNS_ZONE_NAME}"

  cat cf-install-values.yml > "${ROOT_DIR}/cf-install-values/values"
popd
