#!/bin/bash
set -eu

function upload_release() {
  for filename in release-tarball/*.tgz; do
    bosh upload-release --sha2 "$filename"
  done
}

function main() {
  upload_release
}

main
