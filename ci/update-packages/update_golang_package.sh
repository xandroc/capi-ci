#!/bin/bash

set -e -x

cp $PWD/capi-ci-private/ci/private.yml $PWD/capi-release/config/private.yml

pushd golang-release
	new_go_version=$(bosh blobs | grep linux | grep go1. | cut -d . -f 1-3 | sort | tail -1)
popd

cd capi-release

bosh vendor-package golang-1.12-linux ../golang-release

git --no-pager diff packages .final_builds

git config user.name "CAPI CI"
git config user.email "cf-capi-eng+ci@pivotal.io"

git add -A packages .final_builds
git commit -n -m "Bump Golang to $new_go_version"
cp -r $PWD ../updated-capi-release