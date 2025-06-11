#!/bin/bash

[ -z "$SNAPSHOT" ] && SNAPSHOT=2019-10-16
set -o xtrace
exec docker run --rm -ti \
     --name nhess \
     -p 9001:9001 -p 9097:9097 -p 50000:50000 \
     -e SNAPSHOT=2019-10-16 \
     -v $PWD/volumes/cabrc-en-${SNAPSHOT}:/opt/dstar-cab-en:ro \
     -v $PWD/volumes/nhess-server-${SNAPSHOT}:/opt/dstar-ddc-nhess:ro \
     -v $PWD/ddc-en-init.d:/opt/dstar-init.d:ro \
     -v $PWD/ddc-en-conf.d:/opt/dstar-conf.d:ro \
     dstar-runhost:latest
