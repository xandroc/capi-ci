#!/usr/bin/env bash

set -eu

pushd repo
  git rev-parse HEAD > head-tag-file
popd

cp -RP repo/* repo-with-head-tag-file/
