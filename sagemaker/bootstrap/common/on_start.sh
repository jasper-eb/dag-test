#!/bin/bash

set -e

BOOTSTRAP_STAGING_DIR=/tmp/sagemaker_bootstrapping
BOOTSTRAP_REPO_NAME=dag-test.git
BOOTSTRAP_REPO=git@github.com:jasper-eb/$BOOTSTRAP_REPO_NAME
BOOTSTRAP_REPO_RESOURCES_DIR=/sagemaker/bootstrap

# Get the owner of this notebook instance
NOTEBOOK_ARN=$(jq '.ResourceArn' /opt/ml/metadata/resource-metadata.json --raw-output)
USER_TAG=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN | jq '.Tags | .[] | select(.Key == "user") | .Value')
USER=${USER_TAG//\"/}

mkdir $BOOTSTRAP_STAGING_DIR
cd $BOOTSTRAP_STAGING_DIR
git clone $BOOTSTRAP_REPO
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
