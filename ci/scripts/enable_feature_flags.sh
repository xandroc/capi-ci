#!/usr/bin/env bash
set -e -x

source ~/.bashrc

cf api ${CF_API_TARGET} --skip-ssl-validation
cf auth admin ${CF_ADMIN_PASSWORD}
cf enable-feature-flag diego_docker
cf enable-feature-flag task_creation
