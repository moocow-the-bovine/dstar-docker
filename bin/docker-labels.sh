#!/bin/bash

if test "$#" -lt 1 ; then
    echo "Usage: $0 IMAGE" >&2
    exit 1
fi

docker inspect "$@" | json2perl.perl | perl2paths.perl | perl -ne 'print if (s/^\[[0-9]+\]\.ContainerConfig\.Labels\.//);'

