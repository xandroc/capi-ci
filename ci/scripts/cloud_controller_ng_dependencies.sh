#!/usr/bin/env bash

set -e

cd cloud_controller_ng
gemnasium --token $GEMNASIUM_API_KEY dependency_files push -f=Gemfile.lock
dependencies=$(gemnasium --token $GEMNASIUM_API_KEY dependencies list)
red_dependecies=$(echo -en "${dependencies}" | grep "red" | cut -f 2 -d '|' | sed 's/+-- //g')
yellow_dependecies=$(echo -en "${dependencies}" | grep "yellow" | cut -f 2 -d '|' | sed 's/+-- //g')

echo
echo
echo "YELLOW DEPENDENCIES:"
echo "--------------------"
echo -e "${yellow_dependecies}"

if [[ "${red_dependecies}" != "" ]]; then
  echo
  echo
  echo "RED DEPENDENCIES:"
  echo "--------------------"
  echo -e "${red_dependecies}"
  exit 1
fi
