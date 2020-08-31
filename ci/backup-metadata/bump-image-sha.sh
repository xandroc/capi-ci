#!/usr/bin/env bash

set -euo pipefail

LATEST_SHA=$(cat backup-metadata-docker-image/digest)

pushd src/src/backup-metadata/config
  IMAGE=$(yq r cfmetadata.yml spec.containers[0].image | cut -d'@' -f1)
  yq w -i cfmetadata.yml spec.containers[0].image "${IMAGE}@${LATEST_SHA}"

  if [[ `git status --porcelain` ]]; then
    # Changes
    git config --global user.email "cf-lazarus@pivotal.io"
    git config --global user.name "cf-metadata pipeline"
    git add cfmetadata.yml
    git commit -m "Update image SHA used by backup-metadata"
  fi
popd

cp -r src/. backup-metadata-docker-image-updated

