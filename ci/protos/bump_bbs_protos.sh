#!/usr/bin/env bash

pushd capi-release
  source .envrc
  ./src/cloud_controller_ng/scripts/generate-bbs-models.sh
popd

cp -r capi-release/src/cloud_controller_ng bumped/cloud_controller_ng
