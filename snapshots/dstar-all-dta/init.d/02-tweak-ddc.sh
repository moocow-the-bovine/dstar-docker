#!/bin/bash

. /home/ddc-dstar/dstar/docker/dstar-docker-utils.sh

set -o errexit
set -o xtrace

dta_corpora="dta dtak dtae"
dta_port=50000

for c in $dta_corpora ; do
    if [ ! -d /home/ddc-dstar/dstar/corpora/$c/server ] ; then
	echo "$0 - SKIP corpus $c" >&2
	continue
    fi
    cd /home/ddc-dstar/dstar/corpora/$c/server

    #mv etc/ddc_server.cfg etc/ddc_server.cfg_snap
    #mv etc/ddc_local_corpora.cfg etc/ddc_local_corpora.cfg_snap
    #../../../bin/dstar-clone-config.perl "$dta_port" etc/ddc_server.cfg_snap > etc/ddc_server.cfg
    #../../../bin/dstar-clone-config.perl "$dtar_port" etc/ddc_local_corpora.cfg_snap > etc/ddc_local_corpora.cfg
    #rm -f etc/*.cfg_snap

    optfiles=($(compgen -G "index/*.opt" || true))
    if [ "${#optfiles[@]}" -gt 0 ] ; then
	../../../bin/dstar-clone-tweak.sh \
            'if (/^\s*Expand(?:Bibl)?\s/) {
 	    	s{\b(https?)://[^/:]+/dstar/(dta[ke]?)/}{$1://localhost/dstar/$2/}g;
            	s{\bsemq\.fcgi\b}{semq.perl}g;
	    	s{^(.*?https?://(?!(?:localhost)\b))}{#-$1} if (!/pos-ud2stts/);
	     }' \
	     "${optfiles[@]}"
    else
	echo "$0: no opt-files \`index/*.opt' to tweak for corpus '$c'" >&2
    fi
      

    if [ -e "index/$c.opt" ] ; then
	runcmd perl -i -pe 's{(\"\s*)$}{: snapshot 2020-10-05$1} if (/^ServerInfo\s+collectionInfo\s/);' index/$c.opt
    fi
    
    ##-- re-initialize daughter HOST fields in dta/server/etc/ddc_server.cfg
    if [ "$c" = "dta" ] ; then
      make init-meta
    fi

    let dta_port="dta_port+1"
done

