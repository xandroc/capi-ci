#!/usr/bin/env bash
set -e -x

source ~/.bashrc

cf api api.arya.cf-app.com  --skip-ssl-validation
cf auth admin ${CF_ADMIN_PASSWORD}
cf enable-feature-flag diego_docker
cf enable-feature-flag task_creation
cf enable-feature-flag env_var_visibility

bosh -n --color -t $BOSH_DIRECTOR -d $DEPLOYMENT_YML $COMMAND

