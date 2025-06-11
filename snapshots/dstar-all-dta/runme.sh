#!/bin/bash

set -o xtrace
snap=2020-10-05
exec docker run --rm -ti \
     -vdstar-cab-de-$snap:/opt/dstar-cab-de:ro \
     -vdstar-cab-dta-$snap:/opt/dstar-cab-dta:ro \
     -vdstar-ddc-dtak-$snap:/opt/dstar-ddc-dtak:ro \
     -vdstar-web-dtak-$snap:/opt/dstar-web-dtak:ro \
     -v$PWD/init.d:/opt/dstar-init.d:ro \
     -v$PWD/conf.d:/opt/dstar-conf.d:ro \
     dstar-webhost:$snap \
     /bin/bash
