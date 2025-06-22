# syntax=docker/dockerfile:experimental

## IMAGE: dstar-webhost
## "syntax=" line is black magic for docker "secrets" support (incl. ssh forwarding)

FROM dstar-runhost AS runhost

##-- build arguments
ARG dstar_svnroot=https://svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
ARG dstar_svnrev=HEAD

##-- labels (may be clobbered by command-line options to `docker build`; see ../Makefile)
LABEL \
  dstar-docker.project.maintainer="moocow@cudmuncher.de" \
  dstar-docker.project.id="dstar-webhost:bookworm" \
  dstar-docker.project.description="dstar RUNHOST+WEBHOST image"


##-- apt dependencies
WORKDIR /usr/src/dstar-webhost
COPY packages.txt .
RUN cachebuster=1309 \
    apt-get update && apt-get -y install `grep -v '^#' packages.txt`

##-- cpanm dependencies
COPY cpanm.txt .
RUN cachebuster=1249 \
    grep -v '^#' cpanm.txt \
    | while read m ; do \
        test -n "$m" || continue; \
        echo "CPANM $m" >&2; \
	cpanm $m || exit $?; \
      done

##-- apache config
RUN a2enmod cgi \
 && a2enmod headers \
 && a2enmod rewrite \
 && a2enmod perl
COPY apache2 /etc/apache2

##======================================================================
## build : private & build stuff (sensitive svn checkouts, etc.)
FROM runhost AS build

#ADD ssh /root/.ssh

##-- manual dependencies: DDC::Dstar::TimeSeries
#ARG timeseries_co="svn co svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar-timeseries/trunk DDC-Dstar-TimeSeries"
ARG timeseries_co="git clone https://github.com/moocow-the-bovine/ddc-dstar-timeseries.git DDC-Dstar-TimeSeries"
#RUN --mount=type=ssh
RUN \
    cachebust=1621 \
    && set -o xtrace \
    && ${timeseries_co} \
    && cd DDC-Dstar-TimeSeries \
    && perl Makefile.PL \
    && make \
    && make test \
    && make install \
    && make clean

##-- manual dependencies: MUDL (semcloud->DocClassify->MUDL)
#scp kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/deps/MUDL-0.02.tar.gz /dev/stdout | tar xz && cd MUDL-*
#
#ARG MUDL_co="svn co svn+ssh://svn.dwds.de/home/moocow/svn/public/diss-perl/trunk/MUDL MUDL"
ARG MUDL_co="git clone https://github.com/moocow-the-bovine/MUDL.git MUDL"
#RUN --mount=type=ssh
RUN \
    cachebust=1621 \
    && set -o xtrace \
    && ${MUDL_co} \
    && cd MUDL \
    && perl Makefile.PL \
    && make \
    && make test \
    && make install \
    && make clean

##-- manual dependencies: DocClassify (semcloud->DocClassify)
#scp kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/deps/DocClassify-0.21.tar.gz /dev/stdout | tar xz && cd DocClassify-*
#ARG DocClassify_co="svn co svn+ssh://svn.dwds.de/home/moocow/svn/public/classify/trunk DocClassify"
ARG DocClassify_co="git clone https://github.com/moocow-the-bovine/DocClassify.git DocClassify"
#RUN --mount=type=ssh
RUN \
    cachebust=1621 \
    && set -o xtrace \
    && ${DocClassify_co} \
    && cd DocClassify \
    && perl Makefile.PL \
    && make \
    && make test \
    && make install \
    && make clean

##-- manual dependencies: lexdb-icu
#ARG lexdb_icu_co="svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/deps/sqlite-icu"
#ARG lexdb_icu_co="svn co svn+ssh://cudmuncher.de/home/svn/dev/ddc-dstar/deps/sqlite-icu"
ARG lexdb_icu_co="svn co https://svn.code.sf.net/p/ddc-dstar-core/code/deps/sqlite-icu"
#RUN --mount=type=ssh
RUN \
    cachebust=1621 \
    && set -o xtrace \
    && ${lexdb_icu_co} \
    && cd sqlite-icu \
    && make \
    && make install \
    && make clean

##-- setup dstar corpus directory
##  + also update dstar root, just because
WORKDIR /home/ddc-dstar/dstar
ARG dstar_svnrev=HEAD
#RUN --mount=type=ssh
RUN \
    cachebust=1552 \
    set -o xtrace \
    && svn up -r${dstar_svnrev} \
    && ( test -d corpus || svn up -r${dstar_svnrev} --set-depth=files corpus ) \
    && svn up -r${dstar_svnrev} --set-depth=infinity corpus/web \
    && svn up -r${dstar_svnrev} --set-depth=infinity config/corpus/docker.mak \
    && svn up -r${dstar_svnrev} --set-depth=infinity webroot \
    && svn up -r${dstar_svnrev} --set-depth=infinity docker \
    && : -- "save svn recovery metadata (in case of copy)" \
       && svn info corpus > corpus/dstar-docker.svninfo \
    && make -C webroot site.rc \
    && make -C webroot install

##-- cleanup
#RUN rm -rf /root/.ssh

##======================================================================
## deploy: final image
FROM build as deploy
#FROM scratch AS deploy
#COPY --from=build / /

##-- volumes:
##  /opt/dstar-cab-*         : dstar cabx snapshot(s) (resources, cabx, config)
##  /opt/dstar-ddc-*         : dstar ddc snapshot(s) (CORPUS/server, CORPUS/server/etc, config)
##  /opt/dstar-web-*         : dstar ddc snapshot(s) (CORPUS/web, config)
##  /opt/dstar-init*         : initialization hooks (e.g. calls to dstar-docker-mirror-cabx, dstar-docker-mirror-ddc, tweaks)
##  /opt/dstar-conf*         : supervisor *.conf files
#VOLUME /opt/dstar-cab
#VOLUME /opt/dstar-ddc
#VOLUME /opt/dstar-web
#VOLUME /opt/dstar-init.d
#VOLUME /opt/dstar-conf.d

##-- dstar environment
## WEB_SITE_AUTH_EXTERNAL=no : disable external authentication by default (must be configured in container)
## WEB_SITE_PUBLIC=yes       : disable htpasswd authentication (must be configured in container)
ENV \
    WEB_SERVER_HOST=localhost \
    WEB_SERVER_PORT=50000 \
    WEB_WWW_HOST=localhost \
    WEB_CORPUS='$(CORPUS)' \
    WEB_SITE_AUTH_EXTERNAL=no \
    WEB_SITE_PUBLIC=yes \
    dstar_corpus="" \
    dstar_snapshot=""

##-- expose port(s)
EXPOSE 80

##-- re-override command
CMD ["./docker/main"]
