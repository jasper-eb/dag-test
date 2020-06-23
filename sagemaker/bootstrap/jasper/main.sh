#!/bin/bash

set -e

yes | conda create --name main scipy tensorflow pandas presto-client
