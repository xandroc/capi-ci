#!/usr/bin/env bash
set -e -x

source ~/.bashrc

cf api ${CF_API_TARGET} --skip-ssl-validation

set +x
cf auth admin ${CF_ADMIN_PASSWORD}
set -x

cf enable-feature-flag diego_docker
cf enable-feature-flag task_creation
