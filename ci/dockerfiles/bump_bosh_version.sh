#!/usr/bin/env bash

set -exu

BOSH_CLI_VERSION=$(cat bosh-cli-github-release/version)

pushd capi-dockerfiles > /dev/null
  for dockerfile in $(grep -Rl "ENV bosh_cli_version" .); do
    sed -i "s/ENV bosh_cli_version.*$/ENV bosh_cli_version $BOSH_CLI_VERSION/" $dockerfile
  done

   if [[ -n $(git status --porcelain) ]]; then
    git config user.name "CAPI CI"
    git config user.email "cf-capi-eng+ci@pivotal.io"
    git add .
    git commit --allow-empty \
    -m "Update bosh version in Dockerfiles"
  fi
popd > /dev/null

git clone capi-dockerfiles capi-dockerfiles-updated
