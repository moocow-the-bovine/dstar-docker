# syntax=docker/dockerfile:experimental

## IMAGE: dstar-runhost
## "syntax=" line is black magic for docker "secrets" support (incl. ssh forwarding)

##======================================================================
## base : common base
FROM dstar-base AS base

##-- build arguments
ARG dstar_svnroot=https://svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
ARG dstar_svnrev=HEAD

##-- labels (may be clobbered by command-line options to `docker build`; see ../Makefile)
LABEL \
  dstar-docker.project.maintainer="moocow@cudmuncher.de" \
  dstar-docker.project.id="dstar-runhost:buster" \
  dstar-docker.project.description="dstar RUNHOST image"

##-- working directory
WORKDIR /usr/src/dstar-runhost

##-- apt dependencies
COPY packages.txt .
RUN cachebust=1005 \
  apt-get update && apt-get -y install `grep -v '^#' packages.txt`

##-- cpanm dependencies
COPY cpanm.txt .
RUN cachebust=1251 \
  cpanm `grep -v '^#' cpanm.txt`

##======================================================================
## build : build stuff (compilation)
FROM base AS build

##-- build: deps: gfsm
#ARG gfsm_co="svn co svn+ssh://svn.dwds.de/home/moocow/svn/public/gfsm/trunk gfsm"
ARG gfsm_co="git clone https://github.com/moocow-the-bovine/gfsm.git gfsm"
#RUN --mount=type=ssh
RUN \
    cachebust=1551 \
    set -o xtrace \
    && ${gfsm_co} \
    && cd gfsm \
    && ./autoreconf.sh \
    && ./configure \
    && make AM_MAKEFLAGS=-j$(nproc) \
    && make check \
    && make install \
    && make distclean \
    && /sbin/ldconfig \
    && cpanm Gfsm


##-- build: deps: gfsmxl
#ARG gfsmxl_url=http://kaskade.dwds.de/~moocow/projects/gfsm/gfsmxl-0.0.17.tar.gz
#ARG gfsmxl_co="svn co svn+ssh://svn.dwds.de/home/moocow/svn/public/gfsmxl/trunk gfsmxl"
ARG gfsmxl_co="git clone https://github.com/moocow-the-bovine/gfsmxl.git gfsmxl"
#RUN --mount=type=ssh
RUN \
    cachebust=1342 \
    set -o xtrace \
    && ${gfsmxl_co} \
    && cd gfsmxl \
    && ./autoreconf.sh \
    && ./configure \
    && make AM_MAKEFLAGS=-j$(nproc) \
    && make check \
    && make install \
    && make distclean \
    && /sbin/ldconfig \
    && cpanm Gfsm::XL

##-- build: deps: moot
#ARG moot_url=http://kaskade.dwds.de/~moocow/projects/moot/moot-2.0.19-1.tar.gz
#ARG moot_co="svn co svn+ssh://svn.dwds.de/home/svn/dev/moot/trunk moot"
ARG moot_co="git clone https://github.com/moocow-the-bovine/moot.git moot"
#RUN --mount=type=ssh
RUN \
    cachebust=1258 \
    set -o xtrace \
    && ${moot_co} \
    && cd moot \
    && ./autoreconf.sh \    
    && ./configure \
    && make AM_MAKEFLAGS=-j$(nproc) \
    && make check \
    && make install \
    && make distclean \
    && /sbin/ldconfig \
    && cpanm Moot

##-- build: deps: unicruft
## 2020-06-19: using `make -j1` instead of `-j$(nproc)` here
##  + suspect parallelization wonkiness in failed jenkins build dstar-runhost#5 (but can't reproduce)
#ARG unicruft_url=http://svn.dwds.de/~moocow/software/unicruft/unicruft-0.24.tar.gz
#ARG unicruft_co="svn co svn+ssh://svn.dwds.de/home/svn/dev/unicruft/trunk unicruft"
ARG unicruft_co="git clone https://github.com/moocow-the-bovine/unicruft.git unicruft"
#RUN --mount=type=ssh
RUN \
    cachebust=1302 \
    set -o xtrace \
    && ${unicruft_co} \
    && cd unicruft \
    && ./autoreconf.sh \
    && ./configure \
    && make AM_MAKEFLAGS=-j1 \
    && make check \
    && make install \
    && make distclean \
    && /sbin/ldconfig \
    && cpanm Unicruft

##-- build: deps: CAB
RUN cpanm DTA::CAB

##-- build: deps: forkutils
#ARG forkutils_co="svn co svn+ssh://svn.dwds.de/home/svn/dev/forkutils/trunk forkutils"
ARG forkutils_co="git clone https://github.com/moocow-the-bovine/forkutils.git forkutils"
#RUN --mount=type=ssh
RUN \
    cachebust=0833 \
    set -o xtrace \
    && ${forkutils_co} \
    && cd forkutils \
    && perl Makefile.PL \
    && make \
    && make test \
    && make install \
    && make clean

##======================================================================
## build : ddc

##-- ddc build
#ARG ddc_url=https://sourceforge.net/projects/ddc-concordance/files/ddc-concordance/2.1/ddc-2.1.4.tar.gz
#ARG ddc_url=https://sourceforge.net/projects/ddc-concordance/files/ddc-concordance/2.1/ddc-2.1.18-rc1.tar.gz
#ARG ddc_url=https://sourceforge.net/projects/ddc-concordance/files/ddc-concordance/2.1/ddc-2.1.25.tar.gz
#ARG ddc_url=https://sourceforge.net/projects/ddc-concordance/files/ddc-concordance/2.2/ddc-2.2.3.tar.gz
ARG ddc_co="svn co https://svn.code.sf.net/p/ddc-concordance/code/ddc/trunk ddc"
RUN cachebust=1311 \
  set -o xtrace \
  && ${ddc_co} \
  && cd ddc \
  && sh ./autoreconf.sh \
  && sh ./configure FLEX=no BISON=no \
  && make AM_MAKEFLAGS=-j$(nproc) \
  && make install \
  && make distclean \
  && /sbin/ldconfig \
  && ln -s ../lib /usr/local/ddc/lib

##-- ddc-morph build
#ARG ddc_morph_url=https://sourceforge.net/projects/ddc-concordance/files/ddc-morph/2.0/ddc-morph-2.0.1.tar.gz
#ARG ddc_morph_repo=https://svn.code.sf.net/p/ddc-concordance/code/ddc-morph/trunk
ARG ddc_morph_co="svn co https://svn.code.sf.net/p/ddc-concordance/code/ddc-morph/trunk ddc-morph"
RUN \
  set -o xtrace \
  && ${ddc_morph_co} \
  && cd ddc-morph \
  && sh ./autoreconf.sh \
  && sh ./configure \
  && make AM_MAKEFLAGS="-j$(nproc)" \
  && make install \
  && make distclean \
  && /sbin/ldconfig

##======================================================================
## build : extras

#ARG jemalloc_co="svn co svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/deps/jemalloc-stable3 jemalloc-stable3"
#ARG jemalloc_co="svn co svn+ssh://cudmuncher.de/home/svn/dev/ddc-dstar/deps/jemalloc-stable3 jemalloc-stable3"
ARG jemalloc_co="svn co https://svn.code.sf.net/p/ddc-dstar-core/code/deps/jemalloc-stable3 jemalloc-stable3"
#RUN --mount=type=ssh \
RUN \
  cachebust=1818 \
  set -o xtrace \
  && ${jemalloc_co} \
  && cd jemalloc-stable3 \
  && sh ./pull \
  && sh ./configure \
  && make AM_MAKEFLAGS="-j$(nproc)" \
  && make test \
  && make install \
  && make distclean \
  && /sbin/ldconfig


##======================================================================
## deploy : final image (squashed)
FROM build AS deploy
#FROM scratch AS deploy
#COPY --from=build / /

##-- setup: dstar/cabx, dstar/rml.d
#  + also update dstar root, just because
WORKDIR /home/ddc-dstar/dstar
#RUN --mount=type=ssh
RUN \
    cachebust=1551 \
    set -o xtrace \
    && svn up -r${dstar_svnrev} \
    && make -C cabx init \
    && make -C rml.d init \
    && : -- "update svn recovery metadata (in case of copy)" \
       && svn info corpus > corpus/dstar-docker.svninfo

##-- volumes:
##  /opt/dstar-cab-*         : dstar cabx snapshot(s) (resources, cabx, config)
##  /opt/dstar-ddc-*         : dstar ddc snapshot(s) (CORPUS/server, CORPUS/etc, config)
##  /opt/dstar-init*         : initialization hooks (e.g. calls to dstar-docker-mirror-cabx, dstar-docker-mirror-ddc, tweaks)
##  /opt/dstar-conf*         : supervisor *.conf files
#VOLUME /opt/dstar-cab
#VOLUME /opt/dstar-ddc
#VOLUME /opt/dstar-init.d
#VOLUME /opt/dstar-conf.d

##-- environment --> see also dstar/docker/dstar-docker-cabx.conf
ENV \
    DTA_CAB_FORMAT_RAW_DEFAULT_SUBCLASS=DTA::CAB::Format::Raw::Waste \
    TOKWRAP_RCDIR=/home/ddc-dstar/dstar/resources/generic \
    CABX_PLM="" \
    dstar_cabrc_snapver=""

##-- re-override command
CMD ["./docker/main"]
