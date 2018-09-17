#!/bin/bash
set -ex

kubectl expose pod $POD_NAME \
        --type LoadBalancer \
        --port 80 \
        --target-port 5000

cleanup() {
    set +e
    trap - INT TERM
    kubectl delete service $POD_NAME
}
trap cleanup EXIT

trap "exit 42" INT TERM

get_ip() {
    kubectl get service $POD_NAME --no-headers | awk '{print $4}'
}

while [[ "$(get_ip)" == "<pending>" ]]
do
    sleep 5
done

PUBLIC_IP=$(get_ip)

cp /secrets/user* github-tokens
mkdir oauth-token
cp /secrets/oauth-token oauth-token
mkdir gcloud-token
cp /secrets/hail-ci-0-1.key gcloud-token

export SELF_HOSTNAME=http://${PUBLIC_IP}
export BATCH_SERVER_URL=http://batch
source activate hail-ci && ./test-locally.sh
