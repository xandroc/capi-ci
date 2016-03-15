#!/usr/bin/env bash
set -e -x

source ~/.bashrc

pushd capi-release
  CAPI_MASTER_SHA=$(git rev-parse HEAD)
popd

pushd cf-release
  pushd src/capi-release
    git fetch
    git checkout $CAPI_MASTER_SHA
  popd

  set +e
    git diff --exit-code
    exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]
  then
    echo "There are no changes to commit."
  else
    git config user.name "CAPI CI"
    git config user.email "cf-capi-eng+ci@pivotal.io"

    git add src/capi-release

    scripts/staged_shortlog
    scripts/staged_shortlog | git commit -F -
  fi
popd

cp -r cf-release bumped/cf-release
