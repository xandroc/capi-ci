#!/usr/bin/env bash

set -e -x

source ~/.bashrc

VERSION=`cat version/version`

pushd capi-release
  CAPI_COMMIT_SHA=$(git rev-parse HEAD)

  pushd src/cloud_controller_ng
    CC_COMMIT_SHA=$(git rev-parse HEAD)
  popd

  CAPI_RELEASE_OUT="../create-release.out"
  for i in {1..5}; do
    echo "Syncing blobs, attempt $i"
    bosh -n --parallel 10 sync blobs && break
  done

  ./scripts/unused_blobs

  for i in {1..5}; do
    echo "Creating release, attempt $i"
    bosh -n create release --with-tarball --version $VERSION --force | tee -a $CAPI_RELEASE_OUT
    EXIT_STATUS=${PIPESTATUS[0]}
    if [ "$EXIT_STATUS" = "0" ]; then
      break
    fi
  done

  if [ ! "$EXIT_STATUS" = "0" ]; then
    echo "Failed to create CAPI release"
    exit $EXIT_STATUS
  fi

  TARBALL=`grep -a "Release tarball" $CAPI_RELEASE_OUT | cut -d " " -f4`
  if [ "$TARBALL" = "" ]; then
    echo "No release tarball found"
    exit 1
  fi
popd

mv $TARBALL created-capi-release/capi-${CAPI_COMMIT_SHA}-cc-${CC_COMMIT_SHA}.tgz
