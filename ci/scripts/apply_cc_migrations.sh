#!/usr/bin/env bash

set -e -x

source ~/.bashrc

chruby

export DB_CONNECTION_STRING="${CONNECTION_STRING}"
KEY_FILE="${PWD}/capi-ci-private/${ENVIRONMENT}/keypair/bosh.pem"

chmod 600 ${KEY_FILE}
eval `ssh-agent -s`
ssh-add ${KEY_FILE}

cd cloud_controller_ng
bundle install --without development test

# This command creates a tunnel from the concourse job through the bosh director to the VM the CCDB
# is running on. It uses a couple of 'tricks' to ensure the tunnel cleans itself up after the migration
# completes.  See http://www.g-loaded.eu/2006/11/24/auto-closing-ssh-tunnels/

#ssh -Af \                         # carry local ssh keys forward and background the ssh command
#  -o StrictHostKeyChecking=no \   # automatically trust the host as a known_host
#  -o ExitOnForwardFailure=yes \   # auto-close the ssh command when the remote command ends
#  -l vcap \                       # use the vcap user
#  ${TUNNEL_HOST} -L 9000:localhost:9000 \  # forward local connections to port 9000 to port 9000 on the bosh director
#    ssh -Af \                              # carry bosh directory keys forward and background the ssh command
#    -o UserKnownHostsFile=/dev/null \      # b/c we recreate the db vm, we ignore known_hosts file on the bosh director
#    -o StrictHostKeyChecking=no \          # automatically trust the host as a known_host
#    -l vcap \                              # use the vcap user
#    ${DB_HOST} -L 9000:localhost:5524 \    # forward connections on the bosh director port 9000 to port 5524 on the sql db
#      sleep 60  # run a sleep command on the sql db vm, when this ends it will stop the ssh command and b/c of ExitOnForwardFailure
                # the parent ssh command will close itself. the port tunneling that is created will remain
                # open until no activity is occurring on the port.  this is the 'trick' that lets us create a tunnel that
                # will auto-close itself, only after the migration completes#

ssh -Af \
  -o StrictHostKeyChecking=no \
  -o ExitOnForwardFailure=yes \
  -l vcap \
  ${TUNNEL_HOST} -L 9000:localhost:9000 \
    ssh -Af \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -l vcap \
    ${DB_HOST} -L 9000:localhost:5524 \
      sleep 60

bundle exec rake db:dev:migrate
