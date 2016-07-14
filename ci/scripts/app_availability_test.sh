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

  key="capi-ci-private/${ENVIRONMENT}/keypair/bosh.pem"
  chmod 600 ${key}
  eval `ssh-agent -s`
  ssh-add ${key}

  pushd cf-release/src/capi-release/src/cloud_controller_ng
    git checkout "${cloud_controller_branch}"
    bundle install --without development test

    ssh -Af \
      -o StrictHostKeyChecking=no \
      -o ExitOnForwardFailure=yes \
      -l ubuntu \
      ${TUNNEL_HOST} -L 9000:localhost:9000 \
        ssh -Af \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        -l vcap \
        ${DB_HOST} -L 9000:localhost:5524 \
          sleep 60

    bundle exec rake db:migrate
  popd

  # wait for nsync bulker to poll and bbs to potentially kill running app instances
  # sleep 180

  kill -TERM "${polling_pid}"
  exit $EXIT_STATUS
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
