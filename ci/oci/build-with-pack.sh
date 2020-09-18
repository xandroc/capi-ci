#!/bin/bash

set -eu

source capi-ci/ci/docker/common.sh

start_docker

# parameterizing this is hard in place - ADDITIONAL_ARGS is a hack
pack build built-image --builder paketobuildpacks/builder:full --path "source-repository/${CONTEXT_PATH}" ${ADDITIONAL_ARGS}

docker save built-image -o image/image.tar

