#!/bin/bash
set -eu

mkdir -p /home/jumpbox/bbr
mkdir -p /home/jumpbox/tmp
mkdir -p /home/jumpbox/golang
mkdir -p /home/jumpbox/golang/go
mkdir -p /home/jumpbox/golang/go/src/

mkdir -p /home/jumpbox/golang/go/src/github.com
mkdir -p /home/jumpbox/golang/go/src/github.com/cloudfoundry-incubator/
apt-get install -y git

cd /home/jumpbox/golang/go/src/github.com/cloudfoundry-incubator && git clone https://github.com/tcdowney/disaster-recovery-acceptance-tests.git && cd disaster-recovery-acceptance-tests && git checkout add-cf-admin-password-hack

export DEPLOYMENT_TO_BACKUP=cf
export DEPLOYMENT_TO_RESTORE=cf
export BOSH_URL=${BOSH_URL}
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=${BOSH_CLIENT_SECRET}
export CF_ADMIN_PASSWORD=${CF_ADMIN_PASSWORD}
export BOSH_CERT_PATH=/home/jumpbox/bbr/ca_cert.ca
export BBR_BUILD_PATH=/home/jumpbox/bbr/releases/bbr
export GOPATH=/home/jumpbox/golang/go
export PATH=$PATH:$GOPATH/bin
export TMPDIR=/home/jumpbox/tmp

wget https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz -P /tmp && \
  tar xzvf /tmp/go1.9.linux-amd64.tar.gz -C /usr/local && \
  mkdir -p $GOPATH && \
  rm -rf /tmp/*
export PATH=$PATH:/usr/local/go/bin

sudo apt-get install -y --force-yes apt-transport-https
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
# ...then, update your local package index, then finally install the cf CLI
sudo apt-get update -y
sudo apt-get install cf-cli -y

sudo add-apt-repository ppa:masterminds/glide -y && sudo apt-get update -y
sudo apt-get install glide -y

(cd $TMPDIR && wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.31-linux-amd64 -O bosh-cli && chmod +x bosh-cli && mv bosh-cli /usr/local/bin/bosh-cli)
cd /home/jumpbox/bbr
wget https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v1.0.0/bbr-1.0.0.tar
tar -xf bbr-1.0.0.tar
chmod a+x releases/bbr

/home/jumpbox/golang/go/src/github.com/cloudfoundry-incubator/disaster-recovery-acceptance-tests/scripts/run_acceptance_tests.sh
