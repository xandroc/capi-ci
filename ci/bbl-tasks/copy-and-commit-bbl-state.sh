#!/usr/bin/env bash

if [ -z "${REPO_SUBDIRECTORY}" ]; then
    echo "REPO_SUBDIRECTORY has not been set"
    exit 1
fi

cp -rf new-bbl-state/ bbl-state-repo/${REPO_SUBDIRECTORY}

pushd "${PWD}/bbl-state-repo/${REPO_SUBDIRECTORY}"
    status="$(git status --porcelain)"
    if [[ -n "$status" ]]; then
      git config user.name "${GIT_COMMIT_USERNAME}"
      git config user.email "${GIT_COMMIT_EMAIL}"    
      git add --all .
      git commit -m "Copy and commit $(cat new-bbl-state/name) back into bbl-state-repo/${REPO_SUBDIRECTORY}"
    fi
popd

shopt -s dotglob
cp -R "bbl-state-repo/." "updated-bbl-state-repo"
