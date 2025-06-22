# syntax=docker/dockerfile:experimental

## IMAGE: dstar-base
## "syntax=" line is black magic for docker "secrets" support (incl. ssh forwarding)

##======================================================================
## base: base image (shared)
FROM debian:bookworm AS base

##-- build arguments
ARG dstar_svnroot=https://svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
ARG dstar_svnrev=HEAD

#ENV SVN_SSH="/usr/bin/ssh -A -oPreferredAuthentications=publickey -oStrictHostKeyChecking=false -v "
ENV SVN_SSH="/usr/bin/ssh -A -oPreferredAuthentications=publickey -oStrictHostKeyChecking=false "

##-- labels (may be clobbered by command-line options to `docker build`; see ../Makefile)
##-- labels (may be clobbered by command-line options to `docker build`; see ../Makefile)
LABEL \
  dstar-docker.project.maintainer="moocow@cudmuncher.de" \
  dstar-docker.project.id="dstar-base:bookworm" \
  dstar-docker.project.description="dstar base image: common dependencies"

##-- apt dependencies
WORKDIR /usr/src/dstar-base
#COPY sources.list /etc/apt/
COPY packages.txt .
RUN \
    apt-get update && apt-get -y install `grep -v '^#' packages.txt`

RUN \
    cachebuster=1140 \
    true \
    && : -- "create users, groups" \
      && useradd -m -U -d /home/ddc-dstar ddc \
      && useradd -m -U -G ddc -d /home/ddc-admin ddc-admin \
      && echo "export PS1='\\u@\\h:\\w\\\$ '" >>/home/ddc-dstar/.bashrc \
      && echo "export PS1='\\u@\\h:\\w\\\$ '" >>/home/ddc-admin/.bashrc \
    && : -- "useful tweaks" \
      && echo "alias ls='/bin/ls --color=auto -F'" >> /root/.bashrc \
      && echo "alias ll='ls -l'" >> /root/.bashrc \
      && echo "alias la='ls -a'" >> /root/.bashrc \
      && tail -n3 /root/.bashrc >> /home/ddc-dstar/.bashrc \
      && tail -n3 /root/.bashrc >> /home/ddc-admin/.bashrc


##======================================================================
## build : build stuff (svn checkouts, etc.)
FROM base AS build
#COPY --from=base / /

##-- ssh config (default user, known hosts ... NO private keys!)
ADD ssh /root/.ssh

##-- dstar superstructure
WORKDIR /home/ddc-dstar
#RUN --mount=type=ssh
RUN \
    cachebuster=1933 \
    set -o xtrace \
    && : -- "basic checkout" \
      && svn co -r${dstar_svnrev} ${dstar_svnroot} dstar \
    && : -- "prune dstar/doc" \
      && svn up --set-depth=exclude dstar/doc \
    && : -- "save svn recovery metadata (in case of copy)" \
       && svn info dstar/corpus > dstar/corpus/dstar-docker.svninfo \
    && : -- "convenience symlinks" \
      && ln -s /home/ddc-dstar/dstar /dstar \
      && ln -s /home/ddc-dstar/dstar ~/dstar \
      && ln -s /home/ddc-dstar/dstar /home/ddc-admin/dstar

##-- cleanup (not really necessary anymore, since there's no sensitive data here)
#RUN rm -rf /root/.ssh

RUN make -C dstar/init install

##======================================================================
## supervisor : supervisord setup
##  + install supervisord *.conf files to /etc/supervisor/conf.d/

##-- supervisor-stdout : supervisord plugin to dump logs to stdout
RUN \
    cachebuster=1413 \
    set -o xtrace \
    && : "-- Ignore PEP 668 because it's silly" \
       && rm -f /usr/lib/python*/EXTERNALLY-MANAGED \
    && : "-- install supervisor-stdout from git because the PyPI version is stale" \
       && pip install 'supervisor-stdout @ git+https://github.com/coderanger/supervisor-stdout'

COPY \
     docker-supervisor/ README.supervisor \
     /usr/src/dstar-base/docker-supervisor/

COPY etc/ /etc/

##======================================================================
## deploy : final image
#FROM scratch AS deploy
#COPY --from=build / /

##-- common environment
ENV \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  PATH=/dstar/bin:/dstar/script:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOST=docker \
  dstar_svnroot="${dstar_svnroot}" \
  dstar_svnrev="${dstar_svnrev}" \
  dstar_init_hooks="" \
  dstar_init_conf=""

##-- supervisord http gui port
EXPOSE 9001

WORKDIR /home/ddc-dstar/dstar
CMD ["./docker/main"]
