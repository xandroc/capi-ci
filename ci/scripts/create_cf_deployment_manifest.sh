#!/usr/bin/env bash

set -e -x

source ~/.bashrc

cd cf-release

./scripts/generate_deployment_manifest ${INFRASTRUCTURE} ../deployments-runtime/${ENVIRONMENT}/stubs/cf/*.yml > ../generated-manifest/deployment.yml

echo "===GENERATED MANIFEST==="
cat ../generated-manifest/deployment.yml


