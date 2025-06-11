#!/bin/bash

. /home/ddc-dstar/dstar/docker/dstar-docker-utils.sh

runcd /home/ddc-dstar/dstar/corpora/nhess/web

##-- make dhist-cache.json a real file, read-only
## + otherwise dhist-plot.perl tries to update it and fails b/c it's a symlink to a read-only volume
if test -e dhist-cache.json ; then
    runcmd mv dhist-cache.json dhist-cache.json_orig
    runcmd cp -a $(readlink -f dhist-cache.json_orig) dhist-cache.json
    runcmd chmod 0444 dhist-cache.json
fi

##-- add snapshot tag to "acknowledge" template variable
runcmd mv corpus.ttk corpus_orig.ttk
runcmd cp corpus_orig.ttk corpus.ttk
runcmd echo -e "\n##-- snapshot overrides\n[% SET acknowledge = acknowledge _ \": snapshot $SNAPSHOT\" %]" >> corpus.ttk
