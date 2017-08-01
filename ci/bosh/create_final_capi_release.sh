#!/usr/bin/env bash

set -e

source ~/.bashrc

VERSION=`cat version/version`

pushd capi-release
  for i in {1..5}; do
    echo "Syncing blobs, attempt $i"
    bosh sync-blobs --sha2 --parallel=10 && break
  done

  TARBALL_NAME=capi-${VERSION}.tgz
  for i in {1..5}; do
    echo "Creating release, attempt $i"
    bosh create-release --sha2 --tarball=$TARBALL_NAME --version $VERSION --final
    EXIT_STATUS=${PIPESTATUS[0]}
    if [ "$EXIT_STATUS" = "0" ]; then
      break
    fi
  done

  if [ ! "$EXIT_STATUS" = "0" ]; then
    echo "Failed to create CAPI release"
    exit $EXIT_STATUS
  fi

 if [ ! -f $TARBALL_NAME ]; then
    echo "No release tarball found"
    exit 1
 fi

popd

mv capi-release/$TARBALL_NAME created-capi-release/
