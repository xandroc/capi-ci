#!/bin/bash

set -e

cp capi-ci-private/elsa/certs/router/certs.yml capi-ci-private-with-extra
cp elsa-aws-storage-terraform/metadata capi-ci-private-with-extra/s3-terraform-metadata.json
cp capi-ci-private/elsa/bbl-state.json capi-ci-private-with-extra/bbl-state-for-prometheus.json
cat << EOF > capi-ci-private-with-extra/extra-vars.yml
---
new_relic_license_key: $NEW_RELIC_LICENSE_KEY
prometheus_password: $PROMETHEUS_PASSWORD
EOF
