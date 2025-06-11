#!/bin/bash

chdir $(dirname "$0")

set -o xtrace
export DOCKER_BUILDKIT=1
[ -n "$build_opts" ] || build_opts="--squash=true --no-cache=true"

exec docker build --ssh default --progress plain $build_optsd -t dstar-webhost:latest -f Dockerfile .
