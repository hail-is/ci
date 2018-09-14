#!/bin/bash
set -ex

export REPO_NAME=ci-test-$(LC_CTYPE=C LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)

set +x
TOKEN=$(cat github-tokens/user1)
set -x

cleanup() {
    set "" INT TERM
    set +e
    kill $(cat ci.pid)
    rm -rf ci.pid
    set +x
    curl -XDELETE \
         https://api.github.com/repos/hail-ci-test/${REPO_NAME} \
         -H "Authorization: token ${TOKEN}"
    set -x
}
trap cleanup EXIT

trap "exit 24" INT TERM

set +x
curl -XPOST \
     https://api.github.com/orgs/hail-ci-test/repos \
     -H "Authorization: token ${TOKEN}" \
     -d "{ \"name\" : \"${REPO_NAME}\" }"
set -x

rm -rf /tmp/foo
git clone https://github.com/hail-is/ci-test.git /tmp/foo
pushd /tmp/foo
set +x
git remote add new-origin \
    https://${TOKEN}@github.com/hail-ci-test/${REPO_NAME}.git
set -x
git push new-origin master:master
popd

set +x
./setup-endpoints.sh hail-ci-test/${REPO_NAME} ${TOKEN} ${SELF_HOSTNAME}
set -x

export WATCHED_TARGETS='[["hail-ci-test/'${REPO_NAME}':master", true]]'

source activate hail-ci
python ci/ci.py & echo $! > ci.pid
sleep 5
PYTHONPATH=$PYTHONPATH:${PWD}/ci pytest -vv test/test-ci.py
