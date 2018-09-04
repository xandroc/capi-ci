#!/usr/bin/env bash

cd cloud_controller_ng
npm i -g snyk  #TODO: not this
snyk auth $SNYK_TOKEN
snyk test
