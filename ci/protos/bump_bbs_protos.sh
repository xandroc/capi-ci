#!/usr/bin/env bash

ruby_generated_files_path="${PWD}/cloud_controller_ng/lib/diego/bbs/models"

pushd cloud_controller_ng
  # protoc supports ruby natively, but only proto3,
  # We need to create a "new" language (called ruby2) that uses the ruby protobuff gem
  # instead of the native protoc ruby compiler
  # see bbs https://github.com/cloudfoundry/bbs#generating-ruby-models-for-bbs-models
  cp $(bundle exec which protoc-gen-ruby) /usr/local/bin/protoc-gen-ruby2
popd

pushd capi-release
  source .envrc

  bbs_models_path="src/code.cloudfoundry.org/bbs/models"

  pushd "${GOPATH}/${bbs_models_path}"
    # the ruby modules are created based on the package name
    sed -i'' -e 's/package models/package diego.bbs.models/' ./*.proto

    protoc --proto_path="${GOPATH}/src":. --ruby2_out="${ruby_generated_files_path}" ./*.proto
    git checkout .
  popd
popd

pushd cloud_controller_ng
  git add ${ruby_generated_files_path}
  git config user.name 'CAPI CI'
  git config user.email cf-capi-eng+ci@pivotal.io
  git commit -m "Bump bbs protos"
popd

cp -r cloud_controller_ng bumped/cloud_controller_ng
