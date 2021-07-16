#!/usr/bin/env bash
set -e

source ~/.bashrc

pushd cloud_controller_ng
  SOURCE_MASTER_SHA=$(git rev-parse HEAD)
  PASSED_UNIT_TESTS_SHA=$(git log -n1 --format="%H" -- db)
popd

pushd diego-release/src/code.cloudfoundry.org/bbs
  BBS_SHA=$(git rev-parse HEAD)
popd

pushd diego-release/src/code.cloudfoundry.org
  LAGER_SHA=$(cat go.mod | grep 'code.cloudfoundry.org/lager =>') | sed 's/.*-//'
popd

pushd diego-release/src/code.cloudfoundry.org/locket
  LOCKET_SHA=$(git rev-parse HEAD)
popd

pushd cc-uploader
  CC_UPLOADER_SHA=$(git rev-parse HEAD)
popd

pushd tps
  TPS_SHA=$(git rev-parse HEAD)
popd

pushd capi-release
  pushd src/cloud_controller_ng
    git fetch
    git checkout $SOURCE_MASTER_SHA
  popd

  pushd src/code.cloudfoundry.org
    pushd bbs
      git fetch
      git checkout "${BBS_SHA}"
    popd

    pushd lager
      git fetch
      git checkout "${LAGER_SHA}"
    popd

    pushd locket
      git fetch
      git checkout "${LOCKET_SHA}"
    popd

    pushd cc-uploader
      git fetch
      git checkout "${CC_UPLOADER_SHA}"
    popd

    pushd tps
      git fetch
      git checkout "${TPS_SHA}"
    popd
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
    git add src/code.cloudfoundry.org

    scripts/staged_shortlog
    scripts/staged_shortlog | git commit -F -
  fi
popd

cp -r capi-release bumped/capi-release
