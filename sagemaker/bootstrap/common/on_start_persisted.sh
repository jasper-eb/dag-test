#!/bin/bash

function loginfo {
    echo "$(date -Iseconds) $1"
}

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
REQUIREMENTS_DIR=$BOOTSTRAP_STAGING_DIR/$BOOTSTRAP_REPO_NAME/$BOOTSTRAP_REPO_RESOURCES_DIR/$SAGEMAKER_USER

mkdir -p $BOOTSTRAP_STAGING_DIR
cd $BOOTSTRAP_STAGING_DIR

echo "$GITHUB_USER\n$GITHUB_TOKEN" | git clone $BOOTSTRAP_REPO
cd $REQUIREMENTS_DIR

for REQUIREMENTS in *_requirements.txt; do
    KERNEL_NAME=$(echo $REQUIREMENTS | sed 's/\_requirements.txt//g')
    KERNEL_DIR=$USER_KERNEL_DIRECTORY/$KERNEL_NAME
    REQUIREMENTS_FILE=$REQUIREMENTS_DIR/$REQUIREMENTS

    loginfo "Boostrapping $KERNEL_NAME from file $REQUIREMENTS"
    if [[ ! -d $KERNEL_DIR ]]; then
        loginfo "Kernel does not exist in user directory, creating it"
        mkdir -p $KERNEL_DIR
        cd $KERNEL_DIR

        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$KERNEL_DIR/miniconda.sh"
        chmod +x $KERNEL_DIR/miniconda.sh
        bash $KERNEL_DIR/miniconda.sh -b -u -p $KERNEL_DIR/miniconda

        rm -rf $$KERNEL_DIR/miniconda.sh
    fi

    loginfo "Installing/updating requirements"
    source $KERNEL_DIR/miniconda/bin/activate
    pip install -q ipykernel
    pip install -q -r $REQUIREMENTS_FILE # nohup this, make sure environemnt carries over

    loginfo "Registering kernel"
    python -m ipykernel install --user --name $KERNEL_NAME --display-name "$KERNEL_NAME"
    # Symlink to kernelspec path?
    conda deactivate
    loginfo "Kernel $KERNEL_NAME done"
done

loginfo "Bootstrapping complete"

/home/ec2-user/anaconda3/envs/JupyterSystemEnv/bin/python -m ipykernel install --prefix=/home/ec2-user/SageMaker/efs/jasper/kernels/jasper/miniconda --name 'test_jasper'
