#!/usr/bin/env bash
set -e -x

source ~/.bashrc

pushd cloud_controller_ng
  SOURCE_MASTER_SHA=$(git rev-parse HEAD)
  PASSED_UNIT_TESTS_SHA=$(git log -n1 --format="%H" -- db)
popd

pushd cloud_controller_ng-master-migrations
  PASSED_DB_MIGRATIONS_SHA=$(git log -n1 --format="%H" -- db)
popd

echo "Checking if db folder from unit tests is same as db folder from migration tests..."
if [[ $PASSED_UNIT_TESTS_SHA != $PASSED_DB_MIGRATIONS_SHA ]]; then
  echo "The commits do not match; waiting for alignment. Not bumping."
  exit 0
fi

pushd capi-release
  pushd src/cloud_controller_ng
    git fetch
    git checkout $SOURCE_MASTER_SHA
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

    git add src/cloud_controller_ng

    scripts/staged_shortlog
    scripts/staged_shortlog | git commit -F -
  fi
popd

cp -r capi-release bumped/capi-release
