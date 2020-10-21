#!/bin/bash
set -xeu

build_dir=${PWD}

version=$(cat cf-cli/version)
curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${version:1}&source=github-rel" | tar -zx
mv cf7 /usr/local/bin/cf
cf -v

export CONFIG
CONFIG=$(mktemp)

if [ -n "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" ]; then
  echo "Logging into gcloud..."
  gcloud auth activate-service-account \
    "${GOOGLE_SERVICE_ACCOUNT_EMAIL}" \
    --key-file="${GOOGLE_KEY_FILE_PATH}" \
    --project="${GOOGLE_PROJECT_NAME}"
fi

original_config="${build_dir}/integration-config/${CONFIG_FILE_PATH}"
cp ${original_config} ${CONFIG}

CF_GOPATH=/go/src/github.com/cloudfoundry/

echo "Moving capi-bara-tests onto the gopath..."
mkdir -p $CF_GOPATH
cp -R capi-bara-tests $CF_GOPATH

cd /go/src/github.com/cloudfoundry/capi-bara-tests

export CF_DIAL_TIMEOUT=11

export CF_PLUGIN_HOME=$HOME

./bin/test -keepGoing \
  -randomizeAllSpecs \
  -skipPackage=helpers \
  -slowSpecThreshold=300 \
  --flakeAttempts="${FLAKE_ATTEMPTS}" \
  -nodes="${NODES}" \
  -noisySkippings=false \
  . stack
