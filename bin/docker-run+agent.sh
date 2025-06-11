#!/bin/bash

if [ -z "$SSH_AUTH_SOCK" ] ; then
    echo "$0 Warning: variable SSH_AUTH_SOCK is not defined!"
fi
if [ \! -e "$SSH_AUTH_SOCK" ] ; then
    echo "$0 Warning: SSH_AUTH_SOCK=$SSH_AUTH_SOCK does not exist!"
fi

if [ $# -lt 1 -o "$1" = "-h" -o "$1" = "-help" -o "$1" = "--help" ] ; then
    cat <<EOF

Usage: $0 [DOCKER_RUN_ARGS...]

Description:
  Wrapper for \`docker run\` with ssh-agent forwarding via bind-mount
  of \$SSH_AUTH_SOCK.

EOF
    exit 1
fi

set -o xtrace
exec docker run \
     -v "$SSH_AUTH_SOCK:/tmp/ssh-agent-mount.sock" \
     -e "SSH_AUTH_SOCK=/tmp/ssh-agent-mount.sock" \
     "$@"
