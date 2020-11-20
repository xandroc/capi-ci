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
    |          · Real Certs                                                |
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

#### update-bosh

#### bbl-destroy

#### rotate-certs

#### bump-dependencies

### docker-images

### bosh-lite


