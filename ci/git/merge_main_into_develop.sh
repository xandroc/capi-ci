#!/usr/bin/env bash
set -e -u

pushd capi-release
  echo "----- Set git identity"
  git config user.name "CAPI CI"
  git config user.email "cf-capi-eng+ci@pivotal.io"

  echo "----- Adding main cloned release as remote"
  git remote add local-capi-release-main ../capi-release-main
  git fetch local-capi-release-main
  git merge --no-edit local-capi-release-main/main
popd

cp -a capi-release merged/capi-release
