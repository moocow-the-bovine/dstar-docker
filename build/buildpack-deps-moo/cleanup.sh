#!/bin/bash

##======================================================================
## Globals

#ifilter="dangling=true"
dummy=""
list=""
[ -n "$BUILD_ID" ] && curtag="$BUILD_ID" || curtag=0
nprev="1"
force=()
ifilter=""
show_help() {
    cat <<EOF >&2

Usage: $0 [OPTIONS] [IMAGE_NAME]

Options:
  -h          # this help message
  -l          # just list available images
  -c CURTAG   # specify current integer build-tag (default=\$BUILD_ID or 0)
  -p NPREV    # preserve NPREV integer build-tags, including CURTAG (default=1)
  -d          # dummy mode: just print commands
  -f IFILTER  # image search filter (e.g. 'dangling=true')
  -F          # force-remove (passed to 'docker rmi')

Arguments:
  IMAGE_NAME  # target image basename (default=basename \`pwd\`)

Description:
  Prunes docker images matching IMAGE_NAME with integer tags
  less than (TAG-NSAVE).

EOF
}
warn() {
    echo "$0 WARNING: $*" >&2
}
die() {
    echo "$0 ERROR: $*" >&2
    exit 1
}
runcmd() {
    echo "$0 CMD: $*" >&2
    test -n "$dummy" || "$@"
}

##======================================================================
## Command-Line

while getopts "hdlFc:p:f:" param ; do
    case "$param" in
	h) show_help; exit 0;;
	l) list="y" ;;
	d) dummy="y" ;;
	c) curtag="$OPTARG" ;;
	p) nprev="$OPTARG" ;;
	F) force=("-f") ;;
	f) ifilter="--filter $OPTARG" ;;
	*) warn "ignoring unknown option '$param'" ;;
    esac
done
if [ -n "$OPTIND" -a "$OPTIND" -gt 1 ] ; then
    let optshift="$OPTIND-1"
    shift $optshift
fi
[ $# -gt 0 ] && img="$1" || img=$(basename $(pwd))

##======================================================================
## MAIN

##-- list-mode
if test -n "$list" ; then
    runcmd docker images $ifilter "$img"
    exit 0
fi

##-- get minimum save-tag
let mintag="$curtag-$nprev"
echo "$0: base=$img ; current=$curtag ; min=$mintag" >&2

##-- find & untag images (using `docker rmi`)
#docker inspect --format '{{range .RepoTags}}{{.}}{{"\n"}}{{end}}' buildpackd-eps-moo:latest
docker images $ifilter --format '{{.Repository}}\t{{.Tag}}\t{{.ID}}' "$img" | \
    while read repo tag iid ; do
	[[ "$repo" == "$img"   ]] || continue
	[[ "$tag"  == +([0-9]) ]] || continue
	[ "$tag"  -le "$mintag" ]  || continue
	runcmd docker rmi "${force[@]}" "$repo:$tag" \
	       || warn "failed to remove image $repo:$tag ($iid)"
    done

