#!/bin/bash

set -o xtrace
export DOCKER_BUILDKIT=1

#[ -n "$build_opts" ] || build_opts="--squash=true --no-cache=true"
[ -n "$build_opts" ] || build_opts=""

exec docker build --ssh "default" --progress=plain -t dstar-buildhost:latest .
