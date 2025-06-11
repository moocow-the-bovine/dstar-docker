#!/bin/bash

##-- parse args
opts=()
args=()
while [ $# -gt 0 ] ; do
    arg="$1"
    shift
    case "$arg" in
	    --) break ;;
	    *) opts[${#opts[@]}]="$arg" ;;
    esac
done

cmd=(docker run --rm -ti
     --name build-test
     -p 800:80 \
        -p 9001:9001 \
        -v $SSH_AUTH_SOCK:/tmp/ssh-auth-mount.sock
     -e  SSH_AUTH_SOCK=/tmp/ssh-auth-mount.sock
     #-v $HOME/dstar/config:/dstar/config
     -v $HOME/dstar/docker:/dstar/docker
     ##--
     #-v $HOME/dstar/corpora/pnn_test:/dstar/corpora/pnn_test
     #-v $HOME/dstar/sources/pnn_test:/dstar/sources/pnn_test
     ##--
     -v $(readlink -f $(dirname "$0"))/pnn_test:/dstar/corpora/pnn_test
     -v $HOME/dstar/sources/pnn_test/tiny:/dstar/sources/pnn_test
     -v $HOME/dstar/resources:/dstar/resources:ro
     -e dstar_build_uid="${dstar_build_uid:-$(id -u ddc-admin)}"
     -e dstar_build_gid="${dstar_build_gid:-$(id -g ddc-admin)}"
     -e dstar_corpora=pnn_test
     #-e dstar_build_sh_opts="-echo-preset=make-info"
     -e DSTAR_USER="${SUDO_USER:-$(id -un)}"
     ##
     #-e dstar_cabx_run=9096
     -e dstar_cabx_run="dstar-http-9096 dstar-http-en-9097"
     ##
     #-e dstar_cabx_run=""     
     #-e dstar_cabx_relay_host="172.17.0.1"
     #-e dstar_relay_conf="/dstar/docker/relay/cabx-all.rc"
     ##
     "${opts[@]}"
     dstar-buildhost:latest
     "$@"
    )

set -o xtrace
#echo "${cmd[@]}"
exec "${cmd[@]}"
