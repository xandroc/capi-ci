#!/usr/bin/env bash

set -e -x

source ~/.bashrc

echo $PWD
ls

pushd cf-release/src/capi-release/src/cloud_controller
  git checkout migrate
  git pull
popd

cd cf-release

./scripts/generate_deployment_manifest ${INFRASTRUCTURE} ../capi-ci/${ENVIRONMENT}/stubs/cf/*.yml ../capi-ci-private/${ENVIRONMENT}/stubs/cf/*.yml > ../generated-manifest/deployment.yml

echo "===GENERATED MANIFEST==="
cat ../generated-manifest/deployment.yml


