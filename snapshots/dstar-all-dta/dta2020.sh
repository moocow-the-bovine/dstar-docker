#!/bin/bash
#
# File: dta2020/sysv.sh
# Author: Bryan Jurish <jurish@bbaw.de>
# Description: sysv-style init script for dta2020 container
#  + modifed version of: https://gist.github.com/samalba/8bc1f848b4fa2db6f12e

### BEGIN INIT INFO
# Provides:		dta2020
# Required-Start:	$local_fs $remote_fs docker
# Required-Stop:	$local_fs $remote_fs docker
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	Docker service: dta2020 container
### END INIT INFO

set -e

PROJECT_LABEL="dta2020"
PROJECT_DIR=$(dirname $(readlink -f "$0"))
#PROJECT_NAME=dstaralldta
PROJECT_NAME="$PROJECT_LABEL"

YAMLFILE="$PROJECT_DIR/docker-compose.yml"
OPTS="-f $YAMLFILE -p $PROJECT_NAME"
UPOPTS="-d --no-recreate --no-build --no-deps"
FGOPTS="--no-recreate --no-build --no-deps"

. /lib/lsb/init-functions

runcmd() {
    #echo "$0 CMD: $*" >&2
    "$@"
}

##-- change directory
if test -d "$PROJECT_DIR" ; then
  cd "$PROJECT_DIR" || log_failure_msg "failed to chdir to $PROJECT_DIR"
else
  log_failure_msg "project directory $PROJECT_DIR does not exist!"
fi

case "$1" in

    start)
        log_daemon_msg "Starting docker-compose" "$PROJECT_NAME" || true
        runcmd docker-compose $OPTS up $UPOPTS
        ;;

    stop)
        log_daemon_msg "Stopping docker-compose" "$PROJECT_NAME" || true
        runcmd docker-compose $OPTS down
        ;;

    reload)
        log_daemon_msg "Reloading docker-compose" "$PROJECT_NAME" || true
        runcmd docker-compose $OPTS up $UPOPTS
        ;;

    restart)
        runcmd docker-compose $OPTS down
        runcmd docker-compose $OPTS up $UPOPTS
        ;;

    "fg"|start-fg)
        log_daemon_msg "Starting docker-compose" "$PROJECT_NAME" "(foreground)" || true
        runcmd docker-compose $OPTS up $FGOPTS
        ;;

    restart-fg)
        runcmd docker-compose $OPTS down
        runcmd docker-compose $OPTS up $FGOPTS
        ;;
        
    status|st)
        cids=$(docker-compose $OPTS ps -q)
        test -z "$cids" && states="down" \
          || states=$(docker inspect $cids --format '{{.State.Status}}' | env -i sort -u)
	echo "$states"
	test "$states" = "running" && exit 0
	exit 1	   
	;;
        
    ps)
        runcmd docker-compose $OPTS ps
        ;;

    *)
        log_action_msg "Usage: $0 {start|stop|restart|start-fg|restart-fg|reload|status|ps}" || true
        exit 1
        ;;
esac

exit 0
