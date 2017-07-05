#!/usr/bin/env bash
set -e -u

pushd capi-release
  echo "----- Set git identity"
  git config user.name "CAPI CI"
  git config user.email "cf-capi-eng+ci@pivotal.io"

  echo "----- Adding master cloned release as remote"
  git remote add local-capi-release-master ../capi-release-master
  git fetch local-capi-release-master
  git merge --no-edit local-capi-release-master/master
popd

cp -a capi-release merged/capi-release
