#!/bin/bash

set -e

KERNEL_DIR=second
KERNEL_NAME="Second Kernel"

WORKING_DIR="$(pwd)/$KERNEL_DIR"
mkdir -p $WORKING_DIR

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$WORKING_DIR/miniconda.sh"
chmod +x $WORKING_DIR/miniconda.sh
bash $WORKING_DIR/miniconda.sh -b -u -p $WORKING_DIR/miniconda

# Install your dependencies here
source $WORKING_DIR/miniconda/bin/activate
pip install scipy tensorflow pandas presto-client

# Register kernel
pip install ipykernel
python -m ipykernel install --user --name $KERNEL_DIR --display-name "$KERNEL_NAME"

# Cleanup
source $WORKING_DIR/miniconda/bin/deactivate
rm -rf $WORKING_DIR/miniconda.sh
