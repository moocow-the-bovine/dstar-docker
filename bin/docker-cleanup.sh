#!/bin/bash

cfilter="status=exited"
ifilter="dangling=true"
force=()
dummy=""
list=""
show_help() {
    cat <<EOF >&2

Usage: $0 [OPTIONS]

Options:
  -h          # this help message
  -l          # just list things to remove
  -f          # force removal
  -d          # dummy mode: just print commands
  -c CFILTER  # container search filters (default: cfilter)
  -i IFILTER  # image search filter (default: $ifilter)

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

while getopts "hdlfc:i:" param ; do
    case "$param" in
	h) show_help; exit 0;;
	l) list="y" ;;
	d) dummy="y" ;;
	f) force=("-f") ;;
	c) cfilter="$OPTARG" ;;
	i) ifilter="$OPTARG" ;;
	*) warn "ignoring unknown option '$param'" ;;
    esac
done

if test -n "$list" ; then
    runcmd docker ps -af $cfilter
    runcmd docker images -f $ifilter
    exit 0
fi

docker ps -aqf $cfilter \
    | while read c; do
	  runcmd docker rm "${force[@]}" "$c" || warn "failed to remove container '$c'"
      done

docker images -qf $ifilter \
    | while read i; do
	  runcmd docker rmi "${force[@]}" "$i" || warn "failed to remove image '$i'"
      done

