#!/bin/bash
set -ex

REPO_NAME=ci-test-$(LC_CTYPE=C LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)

function cleanup {
    set "" INT TERM
    set +e
    kill $(cat ci.pid)
    rm -rf ci.pid
    curl -XDELETE \
         https://api.github.com/orgs/hail-is/${REPO_NAME} \
         -H "Authorization: token $(cat github-tokesn/user1)" \
}
trap cleanup EXIT

trap "exit 24" INT TERM

curl -XPOST \
     https://api.github.com/orgs/hail-is/repos \
     -H "Authorization: token $(cat github-tokesn/user1)" \
     -d "{ \"name\" : ${REPO_NAME} }"

export WATCHED_TARGETS='[["hail-is/'${REPO_NAME}':master", true]]'

source activate hail-ci
python ci/ci.py & echo $! > ci.pid
sleep 5
PYTHONPATH=$PYTHONPATH:${PWD}/ci pytest -vv test/test-ci.py
