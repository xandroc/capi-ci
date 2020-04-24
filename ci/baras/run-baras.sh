#!/bin/bash
set -xeu

build_dir=${PWD}

sudo cp cf-cli /usr/bin/cf

export CONFIG
CONFIG=$(mktemp)

# original_config="${build_dir}/integration-config/${CONFIG_FILE_PATH}"
# cp ${original_config} ${CONFIG}

CF_GOPATH=/go/src/github.com/cloudfoundry/

echo "Moving capi-bara-tests onto the gopath..."
mkdir -p $CF_GOPATH
cp -R capi-bara-tests $CF_GOPATH

cd /go/src/github.com/cloudfoundry/capi-bara-tests

export CF_DIAL_TIMEOUT=11

export CF_PLUGIN_HOME=$HOME

./bin/test \
-keepGoing \
-randomizeAllSpecs \
-skipPackage=helpers \
-slowSpecThreshold=120 \
-nodes="${NODES}" \
-noisySkippings=false
