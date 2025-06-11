#!/bin/bash

##-- defaults
[ \! -e ~/.docker-registry-client.rc ] || . ~/.docker-registry-client.rc
. $(dirname "$0")/docker-registry-common.sh
prog=$(basename "$0")

set -o pipefail
set -o errexit

##======================================================================
## Command-line

show_help() {
    cat <<EOF >&2

Usage: $prog [OPTIONS] [--] COMMAND [ARG(s)...]

Options:
  -h, -help          # this help message
  -v, -verbose       # be verbose
  -x, -trace         # be very verbose (bash xtrace)
  -d, -dummy         # just print what we would do (DOCKER_REGISTRY_DUMMY)
  -r, -read-only     # just print for destructive operations (DOCKER_REGISTRY_RO)
  -c, -config RCFILE # source bash RCFILE (after ~/.docker-registry-client.rc)

Docker registry commands (for REPO=IMAGE[:TAG])
  catalog [GLOB]              # list registry repositories (image basenames)
  table [GLOB]                # get registry table (REPO:TAG "\t" STAMP "\t" HASH "\n")
  stale REPO[:GLOB] [NKEEP=1] # get list of prunable images for REPO (keep at least NKEEP)
  prune REPO[:GLOG] [NKEEP=1] # prune stale images for REPO (keep at least NKEEP)
  tags REPO[:GLOB]            # list registry tags for repository REPO
  manifest REPO[:TAG]         # get registry manifest for REPO
  xmanifest REPO[:TAG]        # get condensed registry manifest for REPO
  hash REPO[:TAG]             # get registry hash-id for REPO
  stamp REPO[:TAG]            # get registry timestamp for REPO
  delete REPO[:TAG]           # remove REPO from registry

Low-level HTTP request commands (-> curl \${DOCKER_REGISTRY_URL}\${PATH} ...)
  http-head PATH ...
  http-get PATH ...
  http-put PATH ...
  http-post PATH ...
  http-delete PATH ...

Arguments:
  REPO                        # image basename
  REPO[:TAG]                  # image basename with optional tag
  REPO[:GLOB]                 # image basename with optional tag pattern
  GLOB                        # image glob pattern

Environment:
  DOCKER_REGISTRY_URL     # registry URL (=$DOCKER_REGISTRY_URL)
  DOCKER_REGISTRY_DUMMY   # if non-empty, don't actually do anything
  DOCKER_REGISTRY_RO      # if non-empty, don't do anything destructive
  DOCKER_REGISTRY_CURLOPT # additional curl options for registry queries

EOF
}

##======================================================================
## MAIN
rexec() {
    "$@"
    exit $?
}

cmd=""
while [ $# -gt 0 ] ; do
    arg="$1"
    shift
    case "$arg" in
	    ##-- help
	    -h|-help|--help|"help") show_help; exit 1;;
	    -d|-dummy|--dummy|-n|--no-act) DOCKER_REGISTRY_DUMMY=1;;
	    -r|-ro|--ro|-read-only|--read-only) DOCKER_REGISTRY_RO=1;;
	    -c|-config|--config|-rc|--rc) read_rcfile "$1"; shift;;
	    -v|-verbose|--verbose) DOCKER_REGISTRY_VERBOSE=1;;
	    -x|-xtrace|--xtrace|-trace|--trace) DOCKER_REGISTRY_VERBOSE=""; set -o xtrace;;
	    --) break; ;;
	    *) cmd="$arg"; break;;
    esac
done

if [ -z "$cmd" -a $# -lt 1 ] ; then
    echo "$prog: no COMMAND specified" >&2
    show_help
    exit 1
elif [ -z "$cmd" ] ; then
    cmd="$1"
    shift
fi

case "$cmd" in
    ##-- http requests
    http-head|HEAD) rexec rehead "$@";;
    http-get|GET) rexec reget "$@";;
    http-put|PUT) rexec reput "$@";;
    http-post|POST) rexec repost "$@";;
    http-del|http-delete|DEL|DELETE) rexec redel "$@";;
    http-req|http-request|REQ|REQUEST) rexec registry_request "$@";;

    ##-- registry commands
    cat|catalog|l|ls|list) rexec registry_catalog "$@";;
    tags|tag) rexec registry_tags "$@";;
    man|manifest*) rexec registry_manifest "$@";;
    xman|xmanifest*) rexec registry_manifest_ext "$@";;
    "hash") rexec registry_hash "$@";;
    stamp|"time"|timestamp) rexec registry_timestamp "$@";;
    delete|del|rm|remove) rexec registry_delete "$@";;
    table|tab) rexec registry_table "$@";;
    stale|pruneable|prune-list|plist|pls) rexec registry_stale_list "$@";;
    prune) rexec registry_prune "$@";;
    *)
	    echo "$0: unknown command '$cmd'" >&2
	    exit 1
esac
