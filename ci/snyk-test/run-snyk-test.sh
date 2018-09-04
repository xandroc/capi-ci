#!/usr/bin/env bash

npm i -g snyk  #TODO: not this
snyk auth $SNYK_TOKEN
snyk test


