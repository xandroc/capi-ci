#!/bin/bash

set -eu

# ENV
: "${ENVIRONMENT:?}"
: "${DOMAIN:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"
capi_ci_private="${workspace_dir}/capi-ci-private"
updated_capi_ci_private="${workspace_dir}/updated-capi-ci-private"

cats_output_path="${updated_capi_ci_private}/${ENVIRONMENT}/cats_integration_config.json"
lb_output_path="${updated_capi_ci_private}/${ENVIRONMENT}/certs/load-balancer"

# OUTPUTS
function write_cats_config() {
  if [ ! -f "${cats_output_path}" ]; then
    cat <<- EOF > "${cats_output_path}"
{
  "api": "api.${DOMAIN}",
  "apps_domain": "${DOMAIN}",
  "admin_user": "admin",
  "admin_password": "replace-me",
  "skip_ssl_validation": true,
  "backend": "diego",
  "default_timeout": 60,
  "include_sso": true,
  "include_security_groups": true,
  "include_internet_dependent": true,
  "include_services": true,
  "include_v3": true,
  "include_tasks": true,
  "include_route_services": false,
  "include_docker": true,
  "include_ssh": true,
  "use_existing_user": false,
  "keep_user_at_suite_end": false,
  "include_isolation_segments": true,
  "isolation_segment_name": "persistent_isolation_segment"
}
EOF
  fi
}

function write_load_balancer_certs() {
  if [ ! -d "${lb_output_path}" ]; then
    mkdir -p "${lb_output_path}"
    pushd "${lb_output_path}"
      local cert_cn
      cert_cn="*.${DOMAIN}"
      certstrap --depot-path "." init --passphrase '' --common-name "server-ca"
      certstrap --depot-path "." request-cert --passphrase '' --common-name "${cert_cn}"
      certstrap --depot-path "." sign --CA "server-ca" "${cert_cn}"

      mv "${cert_cn}.csr" "server.csr"
      mv "${cert_cn}.crt" "server.crt"
      mv "${cert_cn}.key" "server.key"
    popd
  fi
}

function commit_capi_ci_private() {
  set -x
  if [[ -n $(git status --porcelain) ]]; then
    git config user.name "CI Bot"
    git config user.email "cf-capi-eng@pivotal.io"

    git add "${updated_capi_ci_private}/${ENVIRONMENT}"
    git commit -m "Initial commit for '${ENVIRONMENT}'"
  fi
  set +x
}

git clone "${capi_ci_private}" "${updated_capi_ci_private}"

mkdir -p "${updated_capi_ci_private}/${ENVIRONMENT}"
pushd "${updated_capi_ci_private}/${ENVIRONMENT}"
  write_cats_config
  write_load_balancer_certs

  commit_capi_ci_private
popd

