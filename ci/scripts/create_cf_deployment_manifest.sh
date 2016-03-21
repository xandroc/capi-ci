#!/usr/bin/env bash

set -e -x

source ~/.bashrc

cd cf-release

./scripts/generate_deployment_manifest ${INFRASTRUCTURE} ../capi-ci/${ENVIRONMENT}/stubs/cf/*.yml ../capi-ci-private/${ENVIRONMENT}/stubs/cf/*.yml > ../generated-manifest/deployment.yml

echo "===GENERATED MANIFEST==="
cat ../generated-manifest/deployment.yml


