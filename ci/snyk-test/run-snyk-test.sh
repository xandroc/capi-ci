#!/usr/bin/env bash

cd cloud_controller_ng
snyk auth $SNYK_TOKEN
snyk test
