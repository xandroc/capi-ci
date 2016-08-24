#!/usr/bin/env bash

set -e -x

source ~/.bashrc

function deploy_app() {
  pushd cf-acceptance-tests/assets/dora
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

function migrate_and_kill() {
  declare environment=$1 polling_pid=$2

  set +e

  key="capi-ci-private/${environment}/keypair/bosh.pem"
  chmod 600 ${key}
  eval `ssh-agent -s`
  ssh-add ${key}

  pushd cloud_controller_ng
    ssh \
      -o ExitOnForwardFailure=yes \
      -o StrictHostKeyChecking=no \
      -L 5432:${DB_HOST}:5524 \
      -l ubuntu \
      ${TUNNEL_HOST} \
      -Nf

    bundle exec rake db:migrate

    if [ $? -ne 0 ]; then
      echo "Aborting poller because of migration failure"
      kill -ABRT "${polling_pid}"
      exit
    fi
  popd

  set -e

  echo 'Sleeping to wait for nsync bulker or bbs to potentially kill running app instances'
  sleep 180

  kill -TERM "${polling_pid}"
}

function poll_app() {
  declare app_domain=$1 failures_present=0 should_exit=0 curl_output error_output=""

  trap "should_exit=1" SIGTERM
  trap "failures_present=1; should_exit=1" SIGABRT

  set +ex
  echo "Beginning polling for app availability"
  while [ ${should_exit} -ne 1 ]; do
    curl_output=$(curl -sk https://dora.${app_domain} 2>&1)
    if [ $? -ne 0 ]; then
      failures_present=1
      error_output="${error_output}\n${curl_output}"
      echo -n 'F' >&2
    else
      echo -n '.' >&2
    fi
    sleep 1
  done
  set -ex

  echo "${error_output}" >&2
  exit ${failures_present}
}

function setup_env() {
  declare cloud_controller_branch=$1

  pushd cloud_controller_ng
    git checkout "${cloud_controller_branch}"
    bundle install --without development test
  popd
}

function setup_db() {
  set +x
  export DB_CONNECTION_STRING="${DB}://${DB_USERNAME}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
  set -x
}

function main() {
  setup_env "${CLOUD_CONTROLLER_BRANCH}"
  setup_db

  target_cf "${API_DOMAIN}"
  prepare_cf
  deploy_app

  migrate_and_kill "${ENVIRONMENT}" $$ &
  poll_app "${APP_DOMAIN}"
}

main
