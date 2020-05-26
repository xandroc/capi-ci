#!/bin/bash

set -eu

source capi-ci/ci/docker/common.sh

start_docker

# TODO: parametrize builder?
pack build built-image --builder cloudfoundry/cnb:bionic --path "source-repository/${CONTEXT_PATH}"

docker save built-image -o image/image.tar

