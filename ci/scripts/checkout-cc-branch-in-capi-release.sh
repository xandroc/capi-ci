#!/usr/bin/env bash

set -e -x

source ~/.bashrc

pushd cloud_controller_ng
  CC_CHECKOUT_SHA=$(git rev-parse HEAD)
popd

pushd capi-release/src/cloud_controller_ng
  git checkout $CC_CHECKOUT_SHA
popd
