# capi-ci

Hello, this is the capi team's ci repo. It houses concourse configuration settings for our ci environments.

Check it out! https://capi.ci.cf-app.com/

## Environments

See [pipeline.yml](https://github.com/cloudfoundry/capi-ci/blob/master/ci/pipeline.yml) for more details.

```
   ________________________________________________________________________
 / \                                                                       \
|   |                                                                      |
 \_ |  Elsa: biggest and most "real" environment                           |
    |          · Long-lived                                                |
    |          · HA / Multi-AZ                                             |
    |          · Windows Cell                                              |
    |          · "Real" router certs (via DigiCert)                        |
    |          · Credhub                                                   |
    |          · Database: MySQL                                           |
    |          · Blobstore: S3                                             |
    |                                                                      |
    |  Ripley: used for testing NFS blobstore                              |
    |          · Long-lived                                                |
    |          · Database: MySQL                                           |
    |          · Blobstore: NFS                                            |
    |                                                                      |
    |  Leia: used for testing Azure blobstore                              |
    |          · Long-lived                                                |
    |          · Database: MySQL                                           |
    |          · Blobstore: Azure                                          |
    |                                                                      |
    |  Rey: used for testing GCP blobstore                                 |
    |          · Long-lived                                                |
    |          · Database: MySQL                                           |
    |          · Blobstore: GCP                                            |
    |                                                                      |
    |  Mulan: used for testing Postgres                                    |
    |          · Long-lived                                                |
    |          · Database: Postgres                                        |
    |          · Blobstore: WebDAV                                         |
    |                                                                      |
    |  Kiki: used for testing that db migrations are backwards compatible  |
    |          · Short-lived                                               |
    |          · Database: MySQL                                           |
    |          · Blobstore: WebDAV                                         |
    |                                                                      |
    |  Xena: used for testing BBR on MySQL                                 |
    |          · Short-lived                                               |
    |          · Database: MySQL                                           |
    |          · Blobstore: WebDAV                                         |
    |                                                                      |
    |  Gabrielle: used for testing BBR on Postgres                         |
    |          · Short-lived                                               |
    |          · Database: Postgres                                        |
    |          · Blobstore: WebDAV                                         |
    |                                                                      |
    |  Samus: used for testing cf-for-k8s                                  |
    |          · Short-lived                                               |
    |          · Database: MySQL                                           |
    |          · Blobstore: WebDAV (barely used)                           |
    |                                                                      |
    |                                                                      |    
    |   ___________________________________________________________________|___
    |  /                                                                      /
    \_/______________________________________________________________________/
```


## Pipelines

### capi

This pipeline is responsible for testing, building, and releasing capi-release and capi-k8s-release.

#### capi-k8s-release

This is where the testing for capi-k8s-release components live.

- Runs unit tests for various capi-k8s-release components
- Builds images for the components and deploys to Samus
- Runs CATs & BARAs against Samus

#### capi-release

This is where the majority of testing for capi-release components live.

- Runs unit tests for Cloud Controller and bridge components
- Builds capi-release release candidates and deploys to Elsa, Ripley, Mulan, Kiki, Xena, and Gabrielle 
- Runs appropriate integration tests for each environment
- Bumps the `ci-passed` branch of capi-release

#### blobstore-fanout

Additional blobstore tests that do no block the pipeline. These were removed from the main flow because the backing blobstores were historically flakey. They should be green (or at least not have obviously blobstore-related failures) before cutting a release.

- Deploys to Leia and Rey
- Runs appropriate integration tests

#### ship-it

Jobs responsible for cutting capi-release and capi-k8s-release.

- Bump API versions
- Update API docs
- Release capi-release and capi-k8s-release

#### dependencies-docs

Assortment of jobs for updating docs and other things.

- Update v2 docs every time a new cf-deployment is released
- Update release candidate in v3 docs every time `ci-passed` branch is updated
- Update [checkman](https://github.com/cppforlife/checkman) with pipeline status

#### update-bosh

Updates the bosh deployments for all the pipeline environments (using `bbl up`).

#### bbl-destroy

Theoretically useful for destroying broken bosh deployments for all the pipeline environments. Often doesn't work because the directors are in such bad state.

#### rotate-certs

Rotate the bosh-managed certificates for all the pipeline environments every other month. This prevents the certs from expiring and breaking the pipelines.

#### bump-dependencies

Automatically bumps golang version for capi-release components every time a new [golang-release](https://github.com/bosh-packages/golang-release) is available.

### concourse

Pipeline responsible for updating the concourse deployment that it is running on. Meta!

### docker-images

Build the [docker images](https://github.com/cloudfoundry/capi-dockerfiles) that are used by other pipeline jobs. This is where all the dependencies that we need to run unit tests, acceptance tests, bosh deploys, etc come from.

- Bump bosh CLI version in docker files
- Every week rebuild images used for
   - Pushing release candidate docs
   - Running ruby unit tests
   - Running golang unit tests
   - Running DRATS (for testing BBR)
   - Running migration backwards compatibility tests
   - Running SITS (for testing sync job)
   - Deploying pipeline bosh environments
   - Creating releases and other random things (`runtime-ci` tag)
   - Manging the bosh-lite pool
   - Deploying/Building/Testing cf-for-k8s
   - Building cloud controller with [pack](https://github.com/buildpacks/pack)

### bosh-lite

Pipeline responsible for managing the development [bosh-lite pool](https://github.com/cloudfoundry/capi-env-pool/).

- Delete released bosh-lites
- Create new bosh-lites if there is room in the pool
- Post in slack every week with what bosh lites are claimed in the pool

### streamline-team

Very important pipeline that randomly selects a person every week and posts about it in slack.

### backup-metadata

Tests backup and restore for cf-for-k8s.

