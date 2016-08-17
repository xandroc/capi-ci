#!/usr/bin/env bash

set -e -x

source ~/.bashrc

pushd cf-release/src/capi-release/src/cloud_controller_ng
  git checkout migrate
  git pull
popd

cd cf-release

./scripts/generate_deployment_manifest ${INFRASTRUCTURE} ../capi-ci/${ENVIRONMENT}/stubs/cf/*.yml ../capi-ci-private/${ENVIRONMENT}/stubs/cf/*.yml > ../generated-manifest/cf-deployment-with-dea.yml

echo "===GENERATED MANIFEST==="
cat ../generated-manifest/cf-deployment-with-dea.yml


