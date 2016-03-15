#!/usr/bin/env ruby

require 'tracer'

def sh(command)
  output = `#{command}`
  raise "Command failed: #{command}" unless $?.success?
  output
end

# This class will not be necessary if https://github.com/cppforlife/bosh-hub/issues/8 is completed
class SemVer
  def initialize(version)
    @version = version.split('.').map(&:to_i)
  end

  def <=>(other)
    parts = [version.length, other.version.length].min

    i = 0
    while i < parts
      if version[i] != other.version[i]
        return version[i] <=> other.version[i]
      end
      i += 1
    end

    version.length <=> other.version.length
  end

  attr_reader :version
end

class BoshInit
  def self.install
    sh 'apt-get update'
    sh 'apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3'
    sh "curl #{BoshInit.latest_url} -o /usr/local/bin/bosh-init"
    sh 'chmod +x /usr/local/bin/bosh-init'
  end

  def self.latest_url
    bosh_init_artifacts_location = "https://s3.amazonaws.com/bosh-init-artifacts"
    all_versions = `curl #{bosh_init_artifacts_location}`
    linux_versions = all_versions.scan(/bosh-init-[\d\.]+-linux-amd64/).map { |file| { name: file, version: SemVer.new(file.match(/[\d\.]+/)[0]) } }
    latest_bosh_init_version = linux_versions.sort_by { |a| a[:version] }.last[:name]
    File.join(bosh_init_artifacts_location, latest_bosh_init_version)
  end
end

Tracer.on do
  Tracer.add_filter do |event, file, line, id, binding, klass, *rest|
    file == __FILE__ && klass.to_s != 'SemVer' && klass.to_s != 'BoshInit'
  end

  require 'yaml'
  BoshInit.install

  bosh_url = sh('cat bosh/url').chomp
  bosh_sha1 = sh("openssl sha1 bosh/release.tgz | awk '{print $2}'").chomp

  bosh_aws_cpi_url = sh('cat bosh-aws-cpi/url').chomp
  bosh_aws_cpi_sha1 = sh("openssl sha1 bosh-aws-cpi/release.tgz | awk '{print $2}'").chomp

  aws_stemcell_url = sh('cat aws-stemcell/url').chomp
  aws_stemcell_sha1 = sh("openssl sha1 aws-stemcell/stemcell.tgz | awk '{print $2}'").chomp

  def update_version(config, new_url, new_sha1, name)
    if config['url'] != new_url
      p "Updating #{name} from #{config['url']} to #{new_url}"
      config['url'] = new_url
    end

    if config['sha1'] != new_sha1
      p "Updating #{name} from #{config['sha1']} to #{new_sha1}"
      config['sha1'] = new_sha1
    end
  end

  Dir.chdir(ENV.fetch('BOSH_INIT_CONFIG_DIR')) do
    bosh_config = YAML::load_file('bosh.yml')

    bosh_release = bosh_config['releases'].find { |r| r['name'] == 'bosh' }
    bosh_aws_cpi_release = bosh_config['releases'].find { |r| r['name'] == 'bosh-aws-cpi' }
    aws_stemcell = bosh_config['resource_pools'].find { |rp| rp['name'] == 'vms' }['stemcell']

    update_version(bosh_release, bosh_url, bosh_sha1, 'bosh')
    update_version(bosh_aws_cpi_release, bosh_aws_cpi_url, bosh_aws_cpi_sha1, 'bosh_aws_cpi')
    update_version(aws_stemcell, aws_stemcell_url, aws_stemcell_sha1, 'aws_stemcell')

    File.open('bosh.yml', 'w') { |f| f.write(bosh_config.to_yaml) }

    sh "bosh-init deploy bosh.yml"

    sh 'git config user.name "CAPI CI"'
    sh 'git config user.email "cf-capi-eng+ci@pivotal.io"'
    sh 'git add -A'
    sh "git commit -m 'Bump #{ENV.fetch('BOSH_ENVIRONMENT_NAME')} bosh resources'"
  end

  sh "cp -r capi-ci freshened-config/capi-ci"
end
