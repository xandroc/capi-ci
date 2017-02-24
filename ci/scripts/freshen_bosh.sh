#!/usr/bin/env bash

set -xeu
DIR="$(pwd)"

function commit_bbl_state_file {
  pushd "${DIR}/env-repo"
    if [[ -n $(git status --porcelain) ]]; then
      git config user.name "CAPI CI"
      git config user.email "cf-capi-eng+ci@pivotal.io"
      git add "$BBL_DIR"
      git commit -m "Update bbl artifacts"
    fi
  popd

  pushd "${DIR}"
    shopt -s dotglob
    cp -R env-repo/* updated-env-repo/
  popd
}

trap commit_bbl_state_file EXIT

pushd "env-repo/${BBL_DIR}"
  set +x
  echo "source .envrc"
  source .envrc

  cat certs/load-balancer/*.crt > /tmp/bbl-cert
  cat certs/load-balancer/*.key > /tmp/bbl-key
  set -x

  bbl up --aws-region us-east-1 --iaas aws --aws-bosh-az us-east-1c

  # The two commands below amount to "create or update"
  bbl \
    create-lbs \
    --type=cf \
    --cert=/tmp/bbl-cert \
    --key=/tmp/bbl-key \
    --skip-if-exists

  bbl \
    update-lbs \
    --cert=/tmp/bbl-cert \
    --key=/tmp/bbl-key \
popd
