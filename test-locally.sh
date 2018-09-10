#!/bin/bash
set -ex

REPO_NAME=ci-test-$(LC_CTYPE=C LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)

cleanup() {
    set "" INT TERM
    set +e
    kill $(cat ci.pid)
    rm -rf ci.pid
    curl -XDELETE \
         https://api.github.com/orgs/hail-is/${REPO_NAME} \
         -H "Authorization: token $(cat github-tokens/user1)"
}
trap cleanup EXIT

trap "exit 24" INT TERM

curl -XPOST \
     https://api.github.com/orgs/hail-is/repos \
     -H "Authorization: token $(cat github-tokens/user1)" \
     -d "{ \"name\" : ${REPO_NAME} }"

git clone https://github.com/hail-is/ci-test.git /tmp/foo
pushd /tmp/foo
git remote add new-origin \
    https://$(cat github-tokens/user1)@github.com/hail-is/${REPO_NAME}.git
git fetch new-origin
git push origin new-origin/master:master
popd

export WATCHED_TARGETS='[["hail-is/'${REPO_NAME}':master", true]]'

source activate hail-ci
python ci/ci.py & echo $! > ci.pid
sleep 5
PYTHONPATH=$PYTHONPATH:${PWD}/ci pytest -vv test/test-ci.py
