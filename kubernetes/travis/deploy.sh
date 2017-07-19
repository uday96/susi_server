#!/usr/bin/env bash

export DEPLOY_BRANCH=${DEPLOY_BRANCH:-development}

# if [ "$TRAVIS_REPO_SLUG" != "uday96/susi_server" -o  "$TRAVIS_BRANCH" != "$DEPLOY_BRANCH" ]; then
#     echo "Skip production deployment for a very good reason."
#     exit 0
# fi

export REPOSITORY="https://github.com/${TRAVIS_REPO_SLUG}.git"

sudo rm -f /usr/bin/git-credential-gcloud.sh
sudo rm -f /usr/bin/bq
sudo rm -f /usr/bin/gsutil
sudo rm -f /usr/bin/gcloud

curl https://sdk.cloud.google.com | bash;
source ~/.bashrc
gcloud components install kubectl

gcloud config set compute/zone us-central1-b

# Decrypt the credentials we added to the repo using the key we added with the Travis command line tool
openssl aes-256-cbc -K $encrypted_28cda4aad5d7_key -iv $encrypted_28cda4aad5d7_iv -in susi-server-gcloud-creds.json.enc -out susi-server-gcloud-creds.json -d

gcloud auth activate-service-account --key-file susi-server-gcloud-creds.json
export GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/susi-server-gcloud-creds.json
gcloud config set project susi-server-uday
gcloud container clusters get-credentials susi-server-cluster

cd kubernetes/images

docker build --no-cache -t chiragw15/susi_server:$TRAVIS_COMMIT .
docker login -u="chiragw15" -p="Chirag@1234"
docker tag chiragw15/susi_server:$TRAVIS_COMMIT chiragw15/susi_server:latest
docker push chiragw15/susi_server

kubectl set image deployment/susi-server --namespace=default susi-server=chiragw15/susi_server:$TRAVIS_COMMIT