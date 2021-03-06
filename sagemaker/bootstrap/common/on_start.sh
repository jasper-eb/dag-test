#!/bin/bash

set -e

GITHUB_USER=jasper-eb
GITHUB_TOKEN=$(aws secretsmanager get-secret-value --secret-id jasper | jq '.SecretString' | sed 's/\"{/{/g; s/}\"/}/g; s/\\//g' | jq '.github' | sed 's/\"//g')

BOOTSTRAP_STAGING_DIR=/tmp/sagemaker_bootstrapping
BOOTSTRAP_REPO_NAME=dag-test
BOOTSTRAP_REPO=https://github.com/jasper-eb/$BOOTSTRAP_REPO_NAME.git
BOOTSTRAP_REPO_RESOURCES_DIR=sagemaker/bootstrap

# Get the owner of this notebook instance
NOTEBOOK_ARN=$(jq '.ResourceArn' /opt/ml/metadata/resource-metadata.json --raw-output)
USER=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN | jq '.Tags | .[] | select(.Key == "user") | .Value' | sed 's/\"//g')

yum install expect -y

mkdir $BOOTSTRAP_STAGING_DIR
cd $BOOTSTRAP_STAGING_DIR

echo "$GITHUB_USER\n$GITHUB_TOKEN" | git clone $BOOTSTRAP_REPO
cd $BOOTSTRAP_REPO_NAME/$BOOTSTRAP_REPO_RESOURCES_DIR/$USER

for BOOTSRAP_SCRIPT in *.sh; do
    echo "Running $BOOTSTRAP_REPO_NAME/$BOOTSTRAP_REPO_RESOURCES_DIR/$USER/$BOOTSTRAP_SCRIPT"
    bash $BOOTSRAP_SCRIPT
    if [ $? -eq 0 ]; then
        echo "Script succeeded"
    else
        echo "Script failed"
    fi
done
