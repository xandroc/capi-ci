#!/usr/bin/env bash

set -eu

: "${IGNORED_JOBS:=""}"

ignored_jobs_regex() {
  grep_separator="\\|"
  ignored_jobs_array=(${IGNORED_JOBS})
  regex="$( printf "${grep_separator}%s" "${ignored_jobs_array[@]}" )"
  regex="${regex:${#grep_separator}}" # remove leading separator

  echo "${regex}"
}

atc_url=https://capi.ci.cf-app.com

pushd capi-checkman
  rm -f pipeline

  pipelines=$(curl $atc_url/api/v1/pipelines -s | jq .[].name --raw-output)
  for pipeline in $pipelines; do
    curl -s "https://capi.ci.cf-app.com/api/v1/teams/main/pipelines/$pipeline/jobs" | \
      jq .[].name --raw-output | \
      grep -v "$(ignored_jobs_regex)" | \
      awk -v pipeline="$pipeline" -v atc_url="$atc_url" '{print $1 ": concourse.check " atc_url " main " pipeline " " $1}' \
      >> pipeline
  done

  set +e
  git add -A -N
  git status
  git diff-index --quiet HEAD --
  exit_code=$?
  set -e

  if [[ $exit_code -ne 0 ]]; then
    git config user.name "CAPI CI"
    git config user.email "cf-capi-eng+ci@pivotal.io"

    git add pipeline
    git commit -m "Update pipeline jobs"
  fi
popd

cp -r capi-checkman/. updated-capi-checkman
