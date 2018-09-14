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

# https://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
REPO_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')
cp test-repo/* ${REPO_DIR}
pushd ${REPO_DIR}
set +x
git init
git remote add origin \
    https://${TOKEN}@github.com/hail-ci-test/${REPO_NAME}.git
git add *
git commit -m 'inital commit'
set -x
git push origin master:master
popd

set +x
./setup-endpoints.sh hail-ci-test/${REPO_NAME} ${TOKEN} ${SELF_HOSTNAME}
set -x

export WATCHED_TARGETS='[["hail-ci-test/'${REPO_NAME}':master", true]]'

source activate hail-ci
python ci/ci.py & echo $! > ci.pid
sleep 5
PYTHONPATH=$PYTHONPATH:${PWD}/ci pytest -vv test/test-ci.py
