# syntax=docker/dockerfile:1.0.0-experimental

## IMAGE: buildpack-deps:stretch-moo
## "syntax=" line is black magic for docker "secrets" support (incl. ssh forwarding)

## Build Command (e.g.):
##   docker build . --progress plain -t "buildpack-deps-moo:stretch" -t "buildpack-deps-moo:latest"

##======================================================================
## base: base image (shared)
FROM buildpack-deps:stretch

##-- additional apt dependencies
RUN \
    apt-get update \
    && apt-get -y install libtap-formatter-junit-perl libtap-harness-archive-perl

##-- useful tweaks
RUN \
    echo "alias ls='/bin/ls --color=auto -F'" >> /root/.bashrc \
    && echo "alias ll='ls -l'" >> /root/.bashrc \
    && echo "alias la='ls -a'" >> /root/.bashrc
