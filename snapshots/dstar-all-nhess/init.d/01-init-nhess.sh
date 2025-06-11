#!/bin/bash

dstar_docker=/home/ddc-dstar/dstar/docker
. ${dstar_docker}/dstar-docker-utils.sh

${dstar_docker}/dstar-docker-mirror-cabx      /opt/dstar-cab-en
${dstar_docker}/dstar-docker-mirror-ddc nhess /opt/dstar-ddc-nhess
${dstar_docker}/dstar-docker-mirror-web nhess /opt/dstar-web-nhess
