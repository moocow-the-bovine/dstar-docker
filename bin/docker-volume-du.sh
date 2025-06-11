#!/bin/bash

opts=()
vols=()
image="debian:buster"

show_help() {
    echo "Usage: $0 [-i IMAGE] [DU_OPTIONS] VOLUME(s)..." >&2
}

while test $# -gt 0 ; do
    opt="$1"
    case "$opt" in
	--help)
	    show_help
	    exit 0
	    ;;
    -i)
        shift;
        image="$1"
        ;;
	-*)
	    opts=("${opts[@]}" "$opt")
	    ;;
	*)
	    vols=("${vols[@]}" $(docker volume ls -qf name="$opt"))
	    ;;
    esac
    shift
done

if test "${#vols[@]}" -eq 0 ; then
    echo "$0 ERROR: no volume(s) specified!" >&2
    exit 1
fi


##-- setup mounts
mounts=()
for vol in "${vols[@]}" ; do
    mounts=("${mounts[@]}" -v"$vol:/$vol:ro")
done

exec docker run --rm -w/ "${mounts[@]}" "$image" du "${opts[@]}" "${vols[@]}"
