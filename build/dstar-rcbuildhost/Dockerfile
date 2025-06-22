# syntax=docker/dockerfile:experimental

## IMAGE: dstar-rcbuildhost
## "syntax=" line is black magic for docker "secrets" support (incl. ssh forwarding)

FROM dstar-buildhost AS base

##-- build arguments
ARG dstar_svnroot=https://svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
ARG dstar_svnrev=HEAD

##-- labels (may be clobbered by command-line options to `docker build`; see ../Makefile)
LABEL \
  dstar-docker.maintainer="moocow@cudmuncher.de" \
  dstar-docker.project.id="dstar-rcbuildhost:bookworm" \
  dstar-docker.project.description="dstar RUNHOST+WEBHOST+BUILDHOST+CABRC_BUILDHOST image"

##-- apt dependencies
##  + 32-bit "i386" architecture needed for fsm-3.7
WORKDIR /usr/src/dstar-rcbuildhost
COPY packages.txt .
RUN cachebuster=1309 \
    dpkg --add-architecture i386 \
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

##======================================================================
## build : build & private stuff (svn checkouts, etc.)
FROM base AS build

##-- manual dependencies: via dstar-deps
#ARG dstar_deps_root=svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/deps
#ARG dstar_deps_root=svn+ssh://cudmuncher.de/home/svn/dev/ddc-dstar/deps
ARG dstar_deps_root=https://svn.code.sf.net/p/ddc-dstar-core/code/deps

##-- fsmtools
#ARG dstar_deps_include=fsmtools re2c nolda-xml
#ARG dstar_deps_include="re2c ln-- mootm"
#ARG dstar_deps_include="fsmtools foma-0.9.17"
ARG dstar_deps_include="fsmtools"

##-- dstar/deps packages to build
##  + see also output of `make -C dstar/deps packages`
#ARG dstar_deps_packages="ln-- Algorithm-BinarySearch-Vec Lingua-LTS mootm re2c nolda-xml"
#ARG dstar_deps_packages="fsmtools foma"
ARG dstar_deps_packages="fsmtools"

#RUN --mount-type=ssh
RUN \
    cachebust=1442 \
    && set -o xtrace -o errexit \
    && svn co --ignore-externals --depth=files ${dstar_deps_root} deps \
    && cd deps \
    && ( test -z "${dstar_deps_include}" || svn up ${dstar_deps_include} ) \
    && svn up --set-depth=exclude $(find . -maxdepth 1 -type l | while read l; do test -e $(readlink $l) || echo "$l"; done) \
    && make packages="${dstar_deps_packages}" AM_MAKEFLAGS=-j$(nproc) bootstrap \
    && make clean

##======================================================================
## private: private stuff (suppress docker history)
FROM build as private

##-- 2025-06-09 TODO: port resources-build from cudmuncher svn to git --
#ARG dstar_rcbuild_root=svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/resources-build/trunk
ARG dstar_rcbuild_root=svn+ssh://cudmuncher.de/home/svn/dev/ddc-dstar/resources-build/trunk
ARG dstar_rcbuild_svnrev=HEAD

## we still need --mount-type=ssh here
COPY ssh.private/config /root/.ssh/config
RUN --mount=type=ssh \
    cachebust=2142 \
    set -o xtrace -o errexit \
    && cd /dstar/resources \
    && svn co -r${dstar_rcbuild_svnrev} ${dstar_rcbuild_root} build \
    && chown -R ddc-admin:ddc-admin build \
    && chmod -R g+w build

##-- setup symlinks to non-SVN sources using resources/build/src/README.md conventions
#RUN --mount=type=ssh
RUN \
    cachebust=0852 \
    set -o xtrace -o errexit \
    && cd /dstar/resources/build \
    && : -- "sources: tagh" \
       && mkdir -p morph/ma-morph-src \
       && ln -sfT ../../src/tagh morph/ma-morph-src/current \
    && : -- "sources: tagh-generator" \
      && ln -sfT ../src/tagh-generator/tagh-generator.utf8.tfst tagh-generator/tagh-generator.tfst \
      && ln -sfT ../src/tagh-generator/tagh-generator.utf8.lab tagh-generator/tagh-generator.utf8.lab \
    && : -- "sources: wgetrc (caberr credentials etc)" \
      && ln -sfT src/wgetrc wgetrc

##-- cleanup
#RUN rm -rf /root/.ssh

##======================================================================
## deploy: final image
FROM build AS deploy
COPY --from=private /dstar/resources/build /dstar/resources/build

##-- volumes:
## /dstar/resources/build/src       : non-SVN sources; see svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/resources-build/trunk/src/README.md
#VOLUME /dstar/resources/build/src

##-- dstar environment : TODO
ENV \
  CABRC_INSTALL_ROOT="/dstar/resources/install" \
  CAB_EXLEX_AUTO="no" \
  CABRC_FREE="no" \
  ner_rsync_from="/dstar/resources/build/src/dta-syncope-ner"

##-- re-override workdir & command
WORKDIR /home/ddc-dstar/dstar
CMD ["/usr/bin/make -C /dstar/resources/build"]
