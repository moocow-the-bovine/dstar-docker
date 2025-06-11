#!/bin/bash

. /home/ddc-dstar/dstar/docker/dstar-docker-utils.sh

runcd /home/ddc-dstar/dstar/corpora/nhess/server

runcmd mv etc/ddc_server.cfg etc/ddc_server.cfg_snap
runcmd mv etc/ddc_local_corpora.cfg etc/ddc_local_corpora.cfg_snap
runcmd ../../../bin/dstar-clone-config.perl 50000 etc/ddc_server.cfg_snap > etc/ddc_server.cfg
runcmd ../../../bin/dstar-clone-config.perl 50000 etc/ddc_local_corpora.cfg_snap > etc/ddc_local_corpora.cfg
runcmd rm -f etc/*.cfg_snap
runcmd ../../../bin/dstar-clone-tweak.sh \
       'if (/^\s*Expand\s/) {
         s{\b(https?)://\S+?:9097\b}{$1://cab:9097}g;
         s{\b(https?)://[^/:]+/}{$1://web/}g;
         s{^(.*?https?://(?!(?:cab|web)\b))}{#-$1};
        }' \
       index/*.opt
