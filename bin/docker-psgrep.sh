#!/bin/bash

if test "$#" -lt 1 ; then
    echo "Usage: $0 [GREP_FLAGS] REGEX" >&2
    exit 1
fi

docker ps -a | tail -n +2 | grep "$@" | awk '{print $1}'
