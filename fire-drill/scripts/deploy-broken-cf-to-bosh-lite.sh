#!/bin/bash

set -eu

green='\033[32m'
yellow='\033[33m'
red='\033[31m'
nc='\033[0m'

my_dir="$( cd "$( dirname "$0" )" && pwd )"
ci_dir="$( cd "${my_dir}/../.." && pwd )"
workspace_dir="$( cd "${ci_dir}/.." && pwd )"

cf_deployment_dir="${workspace_dir}/cf-deployment"
deployments_dir="$HOME/deployments/fire-drills"
mkdir -p "${deployments_dir}"

if [ ! -d "${cf_deployment_dir}" ]; then
  echo -e "${green}Grabbing cf-deployment...${nc}"
  git clone https://github.com/cloudfoundry/cf-deployment.git "${cf_deployment_dir}"
fi

# TODO: verify that user has bosh2 and vbox alias
echo -e "${green}Deploying mystery-broken-thing-1...${nc}"
set +e
  # TODO: randomly select a mystery ops file
  # TODO: change the deployment name in the manifest to mystery-broken-thing-1
  bosh2 -n -e vbox -d mystery-broken-thing-1 deploy "${cf_deployment_dir}/cf-deployment.yml" \
    -o "${cf_deployment_dir}/operations/bosh-lite.yml" \
    -v system_domain=bosh-lite.com \
    -v uaa_scim_users_admin_password=admin \
    -o "${ci_dir}/fire-drill/ops-files/mystery-broken-thing-1.yml" \
    --vars-store "${deployments_dir}/mystery-deployment-vars.yml"
set -e

# TODO: print a prompt specific to the given ops file
echo -e "${green}The deploy is finished. Please check that the deployment is broken in the way you expected it to be broken :)${nc}"

echo -e "\n\n${green}##### Goal #####${nc}\n"

echo "The goal of this exercise is to debug a misbehaving CF installation and give a recommendation to an imaginary Operator on how to fix it."
echo "In doing so, hopefully we can grow our understanding of the system we've built and gain empathy for our Operators."

echo -e "\n\n${green}##### Checking your Answer #####${nc}\n"
echo "Once you think you have the solution, try to verify your solution using debugging tools before peeking at the answer."
echo "Check your answer when finished: \`cat "${ci_dir}/fire-drill/ops-files/mystery-broken-thing-1.yml"\`"

echo -e "\n\n${green}##### Prompt for Broken Thing 1 #####${nc}\n"
cat "${ci_dir}/fire-drill/prompts/mystery-broken-thing-1.txt"
