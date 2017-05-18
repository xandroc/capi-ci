#!/bin/bash

set -eu

script_dir="$( cd "$( dirname "$0" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../.." && pwd )"

read_with_escaped_newlines() {
  perl -pe 's|\n|\\n|' "$1"
}

# ENV
: ${ENV_NAME:?}

# INPUTS
capi_ci_private="$( cd "${workspace_dir}/capi-ci-private" && pwd )"

# OUTPUTS
output_dir="$( cd "${workspace_dir}/environment/" && pwd )"
output_name_file="${output_dir}/name"
output_metadata_file="${output_dir}/metadata"

echo "Creating name file..."
echo "${ENV_NAME}" > "${output_name_file}"

echo "Creating bbl vars file..."

pushd "${capi_ci_private}/${ENV_NAME}" > /dev/null

cat <<- EOF > "${output_metadata_file}"
  {
    "deployment": "cf",
    "target": "$(bbl director-address)",
    "client": "$(bbl director-username)",
    "client_secret": "$(bbl director-password)",
    "ca_cert": "$(read_with_escaped_newlines <(bbl director-ca-cert))",
    "gw_user": "vcap",
    "gw_host": "$(bbl director-address | cut -d'/' -f3 | cut -d':' -f1)",
    "gw_private_key": "$(read_with_escaped_newlines <(bbl ssh-key))"
  }
EOF

popd > /dev/null

echo "Successfully created bbl vars file at '${output_metadata_file}'!"
