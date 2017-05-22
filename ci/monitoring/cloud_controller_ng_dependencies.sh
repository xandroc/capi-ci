#!/usr/bin/env bash

set -e

cd cloud_controller_ng

echo "retrieving dependency list"
gemnasium --token $GEMNASIUM_API_KEY dependency_files push -f=Gemfile.lock
dependencies=$(gemnasium --token $GEMNASIUM_API_KEY dependencies list)
echo $dependencies

red_dependencies=$(echo -en "${dependencies}" | grep "red" | cut -f 2 -d '|' | sed 's/+-- //g')
yellow_dependencies=$(echo -en "${dependencies}" | grep "yellow" | cut -f 2 -d '|' | sed 's/+-- //g')

echo
echo
echo "YELLOW DEPENDENCIES:"
echo "--------------------"
echo -e "${yellow_dependencies}"

if [[ "${red_dependencies}" != "" ]]; then
  echo
  echo
  echo "RED DEPENDENCIES:"
  echo "--------------------"
  echo -e "${red_dependencies}"
  exit 1
fi
