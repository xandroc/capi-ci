#!/usr/bin/env ruby

require 'json'

data_file_path = ENV['CF_VERSIONS_FILE_PATH']

cf_deployment_versions = `git -C /Users/pivotal/workspace/cf-deployment tag -l --sort=v:refname`.split
cf_deployment_api_versions_hash = JSON.load(File.open(data_file_path))
latest_known_version =  'v' + cf_deployment_api_versions_hash.first['CF_VERSION']

latest_known_version_index = cf_deployment_versions.index(latest_known_version)

if !latest_known_version_index || latest_known_version == cf_deployment_versions.last
  puts 'No new cf-deployment versions found'
  Process.exit(0)
end

next_version_index = latest_known_version_index + 1
versions_to_add = cf_deployment_versions.slice(next_version_index..-1)

versions_to_add.each do |cf_deployment_version|
  capi_version=`git -C /Users/pivotal/workspace/cf-deployment show #{cf_deployment_version}:cf-deployment.yml | grep capi-release?v= | cut -d'=' -f2`.strip
  cc_version=`git -C /Users/pivotal/workspace/capi-release ls-tree #{capi_version} src/cloud_controller_ng | awk '{print $3}'`.strip
  api_version=`git -C /Users/pivotal/workspace/capi-release/src/cloud_controller_ng show #{cc_version}:config/version_v2`.strip

  trimmed_cf_deployment_version = cf_deployment_version[1..-1]
  new_version_entry = {'CF_VERSION' => trimmed_cf_deployment_version, 'CC_SHA' => cc_version, 'CC_API_VERSION' => api_version}
  cf_deployment_api_versions_hash.unshift(new_version_entry)
end

File.write(data_file_path, JSON.pretty_generate(cf_deployment_api_versions_hash))
