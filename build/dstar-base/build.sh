#!/bin/bash

chdir $(dirname "$0")

set -o xtrace
export DOCKER_BUILDKIT=1
exec docker build --ssh default --progress plain --squash=true --no-cache=true -t dstar-base:latest -f Dockerfile .
