#!/bin/bash

if [ $# -lt 2 ] ; then
    cat <<EOF >&2

Usage: $0 SRC DST

Arguments:
  SRC   # local source image IMAGE[:TAG]
  DST   # registry target HOST[:PORT]/PATH[:TAG]

Description:
  Wrapper for 'tag; push; rmi'.
    docker tag SRC DST
    docker push DST
    docker rmi SRC

EOF
    exit 1
fi

src="$1"
dst="$2"

set -o xtrace
docker tag "$src" "$dst"
docker push "$dst"
docker rmi "$dst"
