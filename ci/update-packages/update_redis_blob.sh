#!/bin/bash

set -e -x

if [[ -z "${PRIVATE_YAML}" ]]; then
  echo "Error: PRIVATE_YAML is not set."
  exit 1
fi

directories=("$PWD/capi-release" "$PWD/capi-release/config" "$PWD/redis-release")
for dir in "${directories[@]}"; do
  if [[ ! -d $dir ]]; then
    echo "Error: Directory $dir does not exist."
    exit 1
  fi
done

echo "${PRIVATE_YAML}" > "$PWD"/capi-release/config/private.yml

capi_blobs_path="$PWD/capi-release/config/blobs.yml"


#e.g. redis/7.0.11
current_redis_blob_name_with_version=$(grep -oP 'redis.*(?=.tar.gz)' "$capi_blobs_path" | head -1) || { echo "Error: grep command failed."; exit 1; }
# e.g. 7.0.11
current_redis_version=$(echo "$current_redis_blob_name_with_version" | awk -F '/' '{print $2}') || { echo "Error: awk command failed."; exit 1; }
echo "Current Redis version is '${current_redis_version}'"

redis_path="$PWD/redis-release"
new_redis_version=$(cat "$redis_path/version") || { echo "Error: cat command failed."; exit 1; }
echo "New Redis version is '${new_redis_version}'"

if [[ "$current_redis_version" == "$new_redis_version" ]]; then
  echo "The current Redis version is the same as the new version. Exiting..."
  exit 0
fi

pushd capi-release
    bosh remove-blob -n "${current_redis_blob_name_with_version}"
    bosh add-blob -n "$redis_path/source.tar.gz" redis/"${new_redis_version}".tar.gz

    sed -i "0,/$current_redis_version/s//$new_redis_version/" packages/redis/packaging || { echo "Error: sed command for 'packaging' failed."; exit 1; }
    sed -i "0,/$current_redis_version/s//$new_redis_version/" packages/redis/README.md || { echo "Error: sed command for 'README' failed."; exit 1; }
    sed -i "0,/$current_redis_version/s//$new_redis_version/" packages/redis/spec || { echo "Error: sed command for 'spec' failed."; exit 1; }

    bosh upload-blobs -n


    git --no-pager diff packages .final_builds config

    git config user.name "CAPI CI"
    git config user.email "cf-capi-eng+ci@pivotal.io"

    git add -A packages .final_builds config
    git commit -n --allow-empty -m "Bump Redis to $new_redis_version"  || { echo "Error: git commit failed."; exit 1; }
    cp -r "$PWD"/. ../updated-capi-release
popd



