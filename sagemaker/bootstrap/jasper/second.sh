#!/bin/bash

set -e

yes | conda create -n jasper_2 python=3.6 pytorch pandas presto-client
