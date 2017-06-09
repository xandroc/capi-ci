#!/bin/bash

set -eu

# ENV
: "${POOL_NAME:="bosh-lites"}"
: "${MESSAGE_PREFIX:=""}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
pool_dir="${workspace_dir}/env-pool/${POOL_NAME}"

# OUTPUTS
output_file="${workspace_dir}/message/message.txt"

pushd "${pool_dir}/claimed" > /dev/null
  claimed_files="$(git log --reverse --name-only --pretty=format: * | xargs)"

  output="*ENV*\t*CLAIMED BY*\t*CLAIMED SINCE*\n"
  for file in ${claimed_files}; do
    file="$( basename "${file}" )"
    author="$(git log --pretty='format:%an' "${file}")"
    committer="$(git log --pretty='format:%cn' "${file}")"
    claimed_since="$(git log --pretty='format:%ar' "${file}")"

    if [ "${author}" != "${committer}" ]; then
      claimed_by="${author}+${committer}"
    else
      claimed_by="${author}"
    fi

    output="${output}${file}\t${claimed_by}\t${claimed_since}\n"
  done

  message="Time for another bosh-lite round-up! If you have a bosh-lite claimed that you no longer need, run \`unclaim_bosh_lite ENV_NAME\` to set it free!"
  if [ -n "${MESSAGE_PREFIX}" ]; then
    message="${MESSAGE_PREFIX} ${message}"
  fi
  echo "${message}" >> "${output_file}"
  echo "" >> "${output_file}"
  echo '```' >> "${output_file}"
  echo -e "${output}" | column -t -s $'\t' >> "${output_file}"
  echo '```' >> "${output_file}"

  echo "Message:"
  cat "${output_file}"
popd > /dev/null
