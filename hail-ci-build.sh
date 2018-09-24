#!/bin/bash

set -ex

cp /secrets/user* github-tokens

mkdir oauth-token
cp /secrets/oauth-token oauth-token

mkdir gcloud-token
cp /secrets/hail-ci-0-1.key gcloud-token

make test-in-cluster
