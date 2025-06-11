#!/bin/bash

. /home/ddc-dstar/dstar/docker/dstar-docker-utils.sh

#set -o xtrace

dta_corpora="dtak dtae dta"
for c in $dta_corpora ; do
    if [ ! -d /home/ddc-dstar/dstar/corpora/$c/web ] ; then
	echo "$0 - SKIP corpus $c" >&2
	continue
    fi
    runcd /home/ddc-dstar/dstar/corpora/$c/web

    ##-- make dhist-cache.json a real file, read-only
    ## + otherwise dhist-plot.perl tries to update it and fails b/c it's a symlink to a read-only volume
    if test -e dhist-cache.json ; then
	runcmd mv dhist-cache.json dhist-cache.json_orig
	runcmd cp -a $(readlink -f dhist-cache.json_orig) dhist-cache.json
	runcmd chmod 0444 dhist-cache.json
    fi

    ##-- use "pure" cgi semcloud
    ## + alternative: setup semq.fcgi server in apache config
    ##    FastCgiServer /home/ddc-dstar/dstar/corpus/web/semcloud/semq.fcgi -socket /tmp/semq.sock -idle-timeout 30 -appConnTimeout 300
    if [ -d semcloud ] ; then
	for f in $(/bin/ls semcloud/*.ttk semcloud/*.js) ; do
	    test -w "$f" || continue
	    runcmd perl -i -pe 's{\bsemq\.fcgi\b}{semq.perl}g;' "$f"
	done
    fi

    ##-- add snapshot tag to "acknowledge" template variable
    runcmd mv corpus.ttk corpus_orig.ttk
    runcmd cp corpus_orig.ttk corpus.ttk
    runcmd echo -e "\n##-- snapshot overrides\n[% SET acknowledge = acknowledge _ \": snapshot $SNAPSHOT\" %]" >> corpus.ttk

done
