# syntax=docker/dockerfile:experimental

## IMAGE: dstar-buildhost
## "syntax=" line is black magic for docker "secrets" support (incl. ssh forwarding)

FROM dstar-webhost AS base

##-- build arguments
ARG dstar_svnroot=https://svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
ARG dstar_svnrev=HEAD

##-- labels (may be clobbered by command-line options to `docker build`; see ../Makefile)
LABEL \
  dstar-docker.maintainer="moocow@cudmuncher.de" \
  dstar-docker.project.id="dstar-buildhost:buster" \
  dstar-docker.project.description="dstar RUNHOST+WEBHOST+BUILDHOST image"

##-- additional sources
COPY docker-ce.list /etc/apt/sources.list.d/docker-ce.list

##-- apt dependencies
##  + 32-bit "i386" architecture needed for fsm-3.7
WORKDIR /usr/src/dstar-buildhost
COPY packages.txt .
RUN cachebuster=1309 \
    dpkg --add-architecture i386 \
    && ( curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - ) \
    && apt-get update \
    && apt-get -y install `grep -v '^#' packages.txt`

##-- cpanm dependencies
#COPY cpanm.txt .
#RUN cachebuster=1309 \
#    grep -v '^#' cpanm.txt \
#    | while read m ; do \
#        test -n "$m" || continue; \
#        echo "CPANM $m" >&2; \
#	cpanm $m || exit $?; \
#      done

##-- locale tweaks
COPY default-locale /etc/default/locale

##======================================================================
## build : build stuff
FROM base AS build


##-- manual dependencies: via dstar-deps
#ARG dstar_deps_root=svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/deps
#ARG dstar_deps_root=svn+ssh://cudmuncher.de/home/svn/dev/ddc-dstar/deps
ARG dstar_deps_root=https://svn.code.sf.net/p/ddc-dstar-core/code/deps

##-- don't include fsmtools by default
#ARG dstar_deps_include=fsmtools re2c nolda-xml
ARG dstar_deps_include="re2c ln-- mootm"

##-- dstar/deps packages to build
##  + see also output of `make -C dstar/deps packages`
#ARG dstar_deps_packages="ln-- Lingua-LTS mootm re2c nolda-xml"
ARG dstar_deps_packages="ln-- Lingua-LTS mootm re2c"

##-- FIXME 2025-06-12: mootm no longer compiles under debian 12 bookworm (g++ 12.2.0-14)

#RUN --mount=type=ssh
RUN \
    cachebust=1125 \
    && set -o xtrace -o errexit \
    && svn co --ignore-externals --depth=files ${dstar_deps_root} deps \
    && cd deps \
    && ( test -z "${dstar_deps_include}" || svn up ${dstar_deps_include} ) \
    && : 'old: svn:externals-based packages' \
       && svn pget svn:externals \
       | grep -Pv '^\s*#' \
       | grep -P '^\^(\S+)\s+(?:ln--|Lingua-LTS|mootm)\s*$' \
       | (while read xurl xdir; do svn co "${dstar_deps_root%/deps}/${xurl#^}" "$xdir" || exit 1; done) \
    && svn up --set-depth=exclude $(find . -maxdepth 1 -type l | while read l; do test -e $(readlink $l) || echo "$l"; done) \
    && make packages="${dstar_deps_packages}" AM_MAKEFLAGS=-j$(nproc) bootstrap \
    && make clean

##-- setup dstar corpus directory from svn
##  + also update dstar root, just because
WORKDIR /home/ddc-dstar/dstar

#RUN --mount=type=ssh
RUN \
    cachebust=1724 \
    set -o xtrace -o errexit \
    && : -- "update base checkout" \
      && svn up -r${dstar_svnrev} \
    && : -- "save svn recovery metadata (in case of naive copy)" \
       && svn info corpus > corpus/dstar-docker.svninfo \
    && : -- "create 'proper' corpus checkout with svn metadata for copy template" \
       && ( test -d corpus.template \
       	    || env DSTAR_SUDO=no ./bin/dstar-checkout-corpus.sh -all corpus.template ) \
    && chown -R ddc-admin:ddc-admin . \
    && chgrp ddc cabx/run \
    && chmod -R g+w .

##-- cleanup
#RUN rm -rf /root/.ssh

##======================================================================
## deploy: final image
FROM build AS deploy

##-- group tweaks (for sudoers umask propagation)
RUN usermod -a -G ddc-admin root

##-- makeTEI placeholder (for apa corpus at ÖAW)
## + DISABLED 2021-07-27: now in "dstar-apa" image
#RUN mkdir -p /dstar/makeTEI \
#    && echo "Dummy placeholder for apa corpus at ÖAW" >/dstar/makeTEI/README.txt \
#    && chown -R ddc-admin.ddc-admin /dstar/makeTEI \
#    && chmod -R 0664 /dstar/makeTEI

##-- dstar environment (defaults)
ENV \
    PATH=/dstar/bin:/dstar/script:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    SVN_SSH="/usr/bin/ssh -a -oPreferredAuthentications=publickey -oStrictHostKeyChecking=false" \
    \
    TOKWRAP_RCDIR="" \
    WEB_SERVER_PORT="" \
    CABX_PLM="" \
    PUBLISH_USER="ddc-admin" \
    CABRC_RSYNC_USER="ddc" \
    CABRC_FREE="yes" \
    DWDS_PIWIK="0" \
    \
    dstar_init_hooks="" \
    dstar_selftest_publish="no" \
    dstar_sync_resources="auto" \
    dstar_sync_rcfiles="" \
    dstar_build_uid="" \
    dstar_build_gid="" \
    dstar_build_umask="002" \
    dstar_corpora="" \
    dstar_checkout_corpus_opts="-force -local-config" \
    dstar_build_sh_opts="-echo-preset=make-info" \
    dstar_cabx_run="9096" \
    dstar_relay_conf="/etc/default/dstar-relay"

#dstar_cabx_run="dstar-http-9096.rc dstar-http-dta-8088.rc dstar-http-dta-9099.rc dstar-http-en-9097.rc dstar-http-taghx-9098.rc"
#dstar_cabx_run="9096 dta-8088 dta-9099 en-9097 taghx-9098"
#dstar_relay_conf="/dstar/docker/relay/cabx-all.rc"
#dstar_archive_dir="/dstar/archive"

##-- re-override command
CMD ["./docker/build"]
