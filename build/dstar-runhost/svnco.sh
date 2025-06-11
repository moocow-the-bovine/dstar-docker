##!/bin/bash -opipefail

## File: svnco.sh
## Description: svn checkout script for CAB docker build
##
## *** UNUSED ***
##  + script is UNUSED as of 2019-10-18
##  + C/C++ sources are pulled from public HTTP-URL ARGs in Dockerfile
##    (gfsm_url, gfsmxl_url, moot_url, unicruft_url)
##  + perl distributions are pulled from CPAN via cpanm
##    (DTA::TokWrap, Lingua::TT, ..., DTA::CAB)

##-- error handling
die() {
    echo "$0 ERROR: $*" >&2
    exit 255
}

##-- utilities
svnco() {
    local wcdir="$1"
    shift
    echo "$0: svn co $* $wcdir" >&2
    svn co "$@" "$wcdir" || die "checkout failed for $wcdir"
}
scptar() {
    echo "$0: scp $* | tar xz" >&2
    scp "$@" /dev/stdout | tar xz || die "unpack failed for $*"
}

##-- checkout: cab (---> UNUSED as of 2019-10-18: sources are pulled from public HTTP URLs; see Dockerfile)
#svnco dta-cab		svn+ssh://svn.dwds.de/home/svn/dev/DTA-CAB/trunk
#svnco dta-tokwrap 	svn+ssh://svn.dwds.de/home/svn/dev/dta-tokwrap/trunk
#svnco GermaNet-Flat	svn+ssh://svn.dwds.de/home/svn/dev/GermaNet-Flat/trunk
#svnco gfsm		svn+ssh://svn.dwds.de/home/moocow/svn/public/gfsm/trunk
#svnco gfsmxl		svn+ssh://svn.dwds.de/home/moocow/svn/public/gfsmxl/trunk
#svnco Lingua-TT	svn+ssh://svn.dwds.de/home/svn/dev/Lingua-TT/trunk
#svnco moot		svn+ssh://svn.dwds.de/home/svn/dev/moot/trunk
#svnco unicruft		svn+ssh://svn.dwds.de/home/svn/dev/unicruft/trunk

##-- scp pseudo-checkouts (--> WEB ONLY)
#scptar kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/deps/DocClassify-0.19.tar.gz
#scptar kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/deps/MUDL-0.01.tar.gz
