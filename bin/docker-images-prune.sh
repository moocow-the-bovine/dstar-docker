#!/bin/bash

##======================================================================
## Globals

set -o errexit
set -o pipefail

prog=$(basename "$0")

show_help() {
    cat <<EOF >&2

Usage: $prog [OPTIONS] [PATTERN]

Options:
  -h, -help            # this help message
  -l, -list            # just list available images
  -d, -dummy           # dummy mode: just print commands
  -k, -keep NKEEP      # retain NKEEP most recent images (default=0:all)
  -x, -exclude REGEX   # exclude lines matching perl-style REGEX
  -f, -filter IFILTER  # image search filter (e.g. 'dangling=true')
  -F, -force           # force-remove (passed to 'docker rmi')
  -D, -dangling        # remove dangling images on success (default:don't)

Arguments:
  PATTERN              # target IMAGE:TAG pattern (default=\$(basename \$(pwd)))

Description:
  Prunes stale docker images matching PATTERN, keeping at least NKEEP
  most recent packages.

EOF
}
info() {
    echo "$prog INFO: $*" >&2
}
warn() {
    echo "$prog WARNING: $*" >&2
}
die() {
    echo "$prog ERROR: $*" >&2
    exit 1
}
runcmd() {
    echo "$prog CMD: $*" >&2
    test -n "$dummy" || "$@"
}



##======================================================================
## Command-Line

list=""
dummy=""
nkeep=0
ifilter=()
force=()
ifilter=()
exclude=''
dangling=y
imgpat=""

while [ $# -gt 0 ] ; do
    arg="$1"
    shift
    case "$arg" in
	    -h|-help|--help) show_help; exit 0;;
	    -l|-ls|-list|--ls|--list) list="y";;
	    -d|-dummy|--dummy|-no-act|--no-act) dummy=y ;;
	    -k|-keep|--keep) nkeep="$1"; shift;;
	    -x|-exclude|--exclude) exclude="$1"; shift;;
	    -f|-filter|--filter) ifilter=(--filter "$1"); shift;;
	    -F|-force|--force) force=("-f") ;;
	    -D|-dangling|--dangling) dangling=y ;;
	    -*) warn "ignoring unknown option '$arg'";;
	    *) imgpat="$arg" ;;
    esac
done
[ -n "$imgpat" ] || imgpat=$(basename $(pwd))
[ -n "$dummy" ] && prog="${prog} (DUMMY)"

##======================================================================
## utils

id_created() {
    local id="$1"
    docker inspect --format '{{.Created}}' "$id"
}

##======================================================================
## MAIN

##-- list-mode
if test -n "$list" ; then
    runcmd docker images "${ifilter[@]}" "$imgpat"
    exit 0
fi

##-- sanity checks
if [ -z "$imgpat" ]; then
    die "no IMGPAT specified!"
elif [ -z "$nkeep" ] ; then
    warn "NKEEP not specified : keeping all images"
    nkeep=0
elif [ $nkeep -lt 0 ] ; then
    warn "NKEEP is negative : keeping all images"
    nkeep=0
fi

##-- find & sort images
#docker inspect --format '{{range .RepoTags}}{{.}}{{"\n"}}{{end}}' buildpackd-eps-moo:latest
#runcmd docker images "${ifilter[@]}" --format '{{.CreatedAt}}\t{{.Repository}}\t{{.Tag}}\t{{.ID}}' "$imgpat" 
rows=$(docker images "${ifilter[@]}" --format "{{.Repository}}:{{.Tag}}\t{{.ID}}" "$imgpat" \
	       | ( [ -z "$exclude" ] && cat || (grep -Pv "$exclude" - || true) ) \
	       | while read img id ; do echo -e "$img\t$id\t$(id_created $id)"; done \
	       | sort -k3)
[ -z "$rows" ] && nrows=0 || nrows=$(echo "$rows" | wc -l)

if [ $nkeep -le 0 -o $nrows -le $nkeep ] ; then
    info "no prunable images for pattern '$imgpat' (keep=$nkeep)"
    [ -z "$rows" ] || (echo "$rows" |  sed 's/^/KEEP	/;')
else
    keeprows=$(echo "$rows" | tail -n $nkeep)
    prunerows=$(echo "$rows" | head -n -$nkeep)
    nprune=$(echo "$prunerows" | wc -l)
    info "found $nprune of $nrows prunable image(s) for pattern '$imgpat' (keep=$nkeep)" >&2

    [ -z "$prunerows" ] || ( echo "$prunerows" | sed 's/^/PRUNE	/;' )
    [ -z "$keeprows" ] || ( echo "$keeprows" | sed 's/^/KEEP	/;' )

    if [ -n "$prunerows" ] ; then
	    echo "$prunerows" \
	        | while read img id created; do runcmd docker rmi "${force[@]}" "$img"; done

	    if [ -n "$dangling" ] ; then
	        runcmd docker images -qa --filter "dangling=true" \
		        | while read id ; do runcmd docker rmi "${force[@]}" "$id" ; done
	    fi
    fi
fi

if [ -n "$dangling" ] ; then
    info "removing dangling images"
    runcmd docker images -qa --filter "dangling=true" \
        | while read id ; do runcmd docker rmi "${force[@]}" "$id" ; done
fi
