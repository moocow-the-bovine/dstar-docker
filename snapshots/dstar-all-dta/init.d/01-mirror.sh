#!/bin/bash

dstar_docker=/home/ddc-dstar/dstar/docker
. ${dstar_docker}/dstar-docker-utils.sh

set -o errexit
set -o xtrace

${dstar_docker}/dstar-docker-mirror-cabx      /opt/dstar-cab-de
${dstar_docker}/dstar-docker-mirror-cabx      /opt/dstar-cab-dta

##-- image default constant WEB_SERVER_PORT=50000 is unsafe for multi-corpus containers
unset WEB_SERVER_PORT

dta_corpora="dtak dtae dta"
for c in $dta_corpora ; do
    if [ \! -e /opt/dstar-ddc-"$c" ] ; then
	echo "$0: SKIP corpus $c" >&2
	continue
    fi
    ${dstar_docker}/dstar-docker-mirror-ddc "$c"  /opt/dstar-ddc-"$c"
    ${dstar_docker}/dstar-docker-mirror-web "$c"  /opt/dstar-web-"$c"
done

