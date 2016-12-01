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
  set -x

  bbl up --aws-region us-east-1

  # The two commands below amount to "create or update"
  certfile=certs/load-balancer/*.crt
  key=certs/load-balancer/*.key

  bbl \
    create-lbs \
    --type=cf \
    --cert="$certfile" \
    --key="$key" \
    --skip-if-exists

  bbl \
    update-lbs \
    --cert="$certfile" \
    --key="$key" \
popd
