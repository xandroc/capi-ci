#!/usr/bin/env bash

set -e -x

source ~/.bashrc

function deploy_app() {
  pushd cf-release/src/github.com/cloudfoundry/cf-acceptance-tests/assets/dora
    cf push dora
  popd
}

function prepare_cf() {
  cf create-org test
  cf create-space -o test test
  cf target -o test -s test
}

function target_cf() {
  declare api_domain=$1

  cf api "${api_domain}" --skip-ssl-validation
  cf auth admin admin
}

function deploy_migrate_and_kill() {
  declare cloud_controller_branch=$1 polling_pid=$2
  bosh_target=$(cat deployments/target)
  bosh_lite_username=$(cat bosh-lite-creds/username)
  bosh_lite_password=$(cat bosh-lite-creds/password)

  mv cloud_controller_ng/db/migrations/* cf-release/src/capi-release/src/cloud_controller_ng/db/migrations

  pushd cf-release
    set +e

    bosh target "${bosh_target}"
    bosh login "${bosh_lite_username}" "${bosh_lite_password}"

    bosh create release cf --force
    EXIT_STATUS=${PIPESTATUS[0]}
    if [ ! "$EXIT_STATUS" = "0" ]; then
      echo "Failed to create cf release"
      kill -TERM "${polling_pid}"
      exit $EXIT_STATUS
    fi

    bosh upload release
    EXIT_STATUS=${PIPESTATUS[0]}
    if [ ! "$EXIT_STATUS" = "0" ]; then
      echo "Failed to upload cf release"
      kill -TERM "${polling_pid}"
      exit $EXIT_STATUS
    fi

    bosh -n deploy
    if [ ! "$EXIT_STATUS" = "0" ]; then
      echo "Failed to deploy cf release"
      kill -TERM "${polling_pid}"
      exit $EXIT_STATUS
    fi
    set -e
  popd

  # wait for nsync bulker to poll and bbs to potentially kill running app instances
  sleep 180

  kill -TERM "${polling_pid}"
}

function poll_app() {
  declare app_domain=$1 failures_present=0 should_exit=0 curl_output

  trap "should_exit=1" SIGTERM

  set +ex
  while [ ${should_exit} -ne 1 ]; do
    curl_output=$(curl -sk https://dora.${app_domain} 2>&1)
    if [ $? -ne 0 ]; then
      failures_present=1
      echo >&2
      echo 'Failed when curling app' >&2
      echo "${curl_output}" >&2
    fi
    echo -n '.' >&2
    sleep 1
  done
  set -ex

  exit ${failures_present}
}

function main() {
  target_cf "${API_DOMAIN}"
  prepare_cf
  deploy_app

  deploy_migrate_and_kill "${CLOUD_CONTROLLER_BRANCH}" $$ &
  poll_app "${APP_DOMAIN}"
}

main
