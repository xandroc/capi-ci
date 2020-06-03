#!/usr/bin/env bash

set -eu

eval "$(bbl print-env --state-dir=bbl-state/${BBL_STATE_DIR})"

credhub api

credhub curl -p "/api/v1/data?name=${CERTIFICATE_NAME}" > /tmp/credhub-output.json

cat /tmp/credhub-output.json | jq ".data[0] | {name, type, value} | .name = \"${BACKUP_NAME}\"" > /tmp/backup-request.json

# create the backup credential
credhub curl -p /api/v1/data -X=PUT -d="$(cat /tmp/backup-request.json)" 1>/dev/null

