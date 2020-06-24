#!/bin/bash

set -e

NOTEBOOK_ARN=$(jq '.ResourceArn' /opt/ml/metadata/resource-metadata.json --raw-output)
SAGEMAKER_USER=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN | jq '.Tags | .[] | select(.Key == "user") | .Value' | sed 's/\"//g')

GITHUB_USER=$(aws secretsmanager get-secret-value --secret-id $SAGEMAKER_USER | jq '.SecretString' | sed 's/\"{/{/g; s/}\"/}/g; s/\\//g' | jq '.github_user' | sed 's/\"//g')
GITHUB_TOKEN=$(aws secretsmanager get-secret-value --secret-id $SAGEMAKER_USER | jq '.SecretString' | sed 's/\"{/{/g; s/}\"/}/g; s/\\//g' | jq '.github_token' | sed 's/\"//g')

BOOTSTRAP_STAGING_DIR=/tmp/sagemaker_bootstrapping
BOOTSTRAP_REPO_NAME=dag-test
BOOTSTRAP_REPO=https://github.com/jasper-eb/$BOOTSTRAP_REPO_NAME.git
BOOTSTRAP_REPO_RESOURCES_DIR=sagemaker/bootstrap

USER_KERNEL_DIRECTORY=/home/ec2-user/SageMaker/efs/$SAGEMAKER_USER/kernels
REQUIREMENTS_DIR=$BOOTSTRAP_REPO_NAME/$BOOTSTRAP_REPO_RESOURCES_DIR/$SAGEMAKER_USER

mkdir $BOOTSTRAP_STAGING_DIR
cd $BOOTSTRAP_STAGING_DIR

echo "$GITHUB_USER\n$GITHUB_TOKEN" | git clone $BOOTSTRAP_REPO

for REQUIREMENTS in $REQUIREMENTS_DIR/*_requirements.txt; do
    KERNEL_DIR=$USER_KERNEL_DIRECTORY/$KERNEL_NAME
    KERNEL_NAME=$(echo $REQUIREMENTS | sed 's/\_requirements.txt//g')
    REQUIREMENTS_FILE=$REQUIREMENTS_DIR/$REQUIREMENTS

    echo "$(date -Iseconds) Boostrapping $KERNEL_NAME from file $REQUIREMENTS"
    if [[ ! -d $KERNEL_DIR ]]; then
        echo "$(date -Iseconds) Kernel does not exist in user directory, creating it"
        mkdir -p $KERNEL_DIR
        cd $KERNEL_DIR

        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$KERNEL_DIR/miniconda.sh"
        chmod +x $KERNEL_DIR/miniconda.sh
        bash $KERNEL_DIR/miniconda.sh -b -u -p $KERNEL_DIR/miniconda

        rm -rf $$KERNEL_DIR/miniconda.sh
    fi

    echo "$(date -Iseconds) Installing/updating requirements"
    source $$KERNEL_DIR/miniconda/bin/activate
    pip install -r $REQUIREMENTS_FILE

    echo "$(date -Iseconds) Registering kernel"
    python -m ipykernel install --user --name $KERNEL_DIR --display-name "$KERNEL_NAME"

    conda deactivate
    echo "$(date -Iseconds) Kernel $KERNEL_NAME done"
done

echo "$(date -Iseconds) Bootstrapping complete"
