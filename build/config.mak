##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: dstar-docker/config.mak
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: common configuration for dstar docker builds

##======================================================================
## Variables

##-------------------------------------------------------------
## Variables: make

## SHELL
export SHELL = /bin/bash -o pipefail

.SECONDARY:
.DELETE_ON_ERROR:

## CLEAN_FILES : files to remove on 'make clean'
CLEAN_FILES ?= tag.id img.id img-*.id con.id export.id image.tar.gz export.tar.gz *.stamp
CLEANER_FILES ?=
REALCLEAN_FILES ?=

## CLEAN_DIRS : dirs to remove on 'make clean'
CLEAN_DIRS ?=
CLEANER_DIRS ?=
REALCLEAN_DIRS ?=

##-------------------------------------------------------------
## Variables: commands & useful tidbits

## docker : docker command
docker ?= docker

## imgid : shell snippet for getting current image-id
imgid ?= $$(cat img.id 2>/dev/null)

## conid : shell snippet for getting current container-id
conid ?= $$(cat con.id 2>/dev/null)

## DOCKER_BUILDKIT : enable "buildkit" docker enhacements (incl. 'docker build --ssh' option)
##  + see https://docs.docker.com/develop/develop-images/build_enhancements/
DOCKER_BUILDKIT = 1
export DOCKER_BUILDKIT

##-------------------------------------------------------------
## Variables: docker "repository" tags

## "repository" tag syntax, for use e.g. as `docker tag -t $(repo) IMAGE`
##   repo      = $(repopath):$(repotag)
##   repopath  = $(repodir)$(repobase)
##   repodir  ?= 
##   repobase ?= $(notdir $(CURDIR))
##   repotag  ?= latest

## repodir : image repository "directory" prefix INCLUDING trailing "/"
##   + setting this to empty (default) creates a "pure" local tag
#repodir ?= de.dwds/
#repodir ?= cudmuncher/
repodir ?=

## package : image repository basename
repobase ?= $(notdir $(CURDIR))

## repotag : image repsitory "tag" (~ version) for build
#repotag ?= 2017-0
repotag ?= latest

## repopath : image repository path ("directory" prefix + basename)
repopath ?= $(repodir)$(repobase)

## repo : docker image "repository" la https://docs.docker.com/engine/reference/commandline/tag
repo ?= $(repopath):$(repotag)

## tagas : target tag(s) for `make tag`, empty for none
#tagas ?=
#tagas ?= 2017-09-27
#tagas ?= 2018-10-24
#tagas ?= 2019-10-16
#tagas ?= 2020-03-27
#tagas  ?= 2020-10-05
#tagas  ?= 2025-06-11 latest
#tagas  ?= 2025-06-21 latest
#--
tagas  ?= 2025-06-22 bookworm latest

## tagpath : target repo path for `make tag`
tagpath ?= $(repopath)

## tagrepos : target REPO:TAG(s) for `make tag`
tagrepos ?= $(addprefix $(tagpath):,$(tagas) $(if $(filter $(disttag),$(tagas)),,$(disttag)))

## tag_enabled : empty or "no" disables
tag_enabled ?= $(if $(tagas),yes,no)

##-------------------------------------------------------------
## Variables: docker build

## buildid : common build-id
buildid ?= $(repobase):$(repotag)

## labns : namespace for common labels INCLUDING trailing "."
labns ?= $(if $(repodir),$(repodir:/=.),dstar-docker.)

## buildlab : label for common build-id
buildlab ?= $(labns)project.id

## dockerlabels : common labels (used by default 'build' rule)
dockerlabels ?= \
	$(labns)project.head=$(shell git rev-parse HEAD)

## buildstages : build stages (empty for single-FROM build)
#buildstages ?=

## dockerargs : common --build-arg options (used by default 'build' rule)
dockerargs ?= $(dstar_svnargs)

## dockersecrets : common --secret options for `docker build`+
#comma := ,
#dockersecrets ?= $(if $(SSH_AUTH_SOCK),id=ssh_auth_sock$(comma)src=$(SSH_AUTH_SOCK))

## dockerssh : common --ssh options for `docker build`
comma := ,
dockerssh ?= default

## buildsquash : docker --squash argument
## + 2025-06-04 ::DEPRECATED::
#buildsquash ?= --squash=true
buildsquash ?=

## dockerbuild : additional options for `docker build`
#dockerbuild ?=

##-------------------------------------------------------------
## Variables: docker run

## dockerrun : additional options for `docker run`
#dockerrun ?=

##-------------------------------------------------------------
## Variables: dist

## distdir : distribution directory
distdir ?= ../../dist

## disttag : distribution tag
disttag ?= $(if $(tagas),$(firstword $(tagas)),$(repotag))

## distbase : distribution basename
distbase ?= $(repobase)-$(disttag)

## distfiles : distribution file basenames
distfiles ?= $(addprefix $(distbase).,$(if $(wildcard Dockerfile),image.tar.gz))

##-------------------------------------------------------------
## Variables: publish

## publish_dst : destination rsync URL for publish
publish_dst ?= services3.dwds.de:dstar-docker/dist/

## publish_rsync : publish command
publish_rsync ?= rsync -ulptg --verbose

##-------------------------------------------------------------
## Variables: push

## push_prefix : destination prefix for push, INCLUDING trailing "/"
push_prefix ?= $(if $(repodir),$(repodir),cudmuncher/)

## push_repo : destination basename for push, INCLUDING namespace
push_repo ?= $(if $(repodir),$(repodir),cudmuncher/)$(repobase)

## push_tags : tags to be pushed (empty to suppress push)
push_tags ?= $(sort $(repotag) $(tagas))

## push_options : options for docker push
push_options ?= -q

## push_enabled : empty or "no" disables
push_enabled ?= $(if $(push_tags),yes,no)

##-------------------------------------------------------------
## Variables: dstar

## dstar_template_idfile : dstar template image-id file
dstar_template_idfile ?= ../dstar-base/img.id

##-------------------------------------------------------------
## Variables: docker-compose stuff

## docker_compose : docker-compose executable
docker_compose ?= docker-compose

## compose_project : docker-compose project name
compose_project ?= $(shell echo "$(notdir $(CURDIR))" | tr -dC a-z0-9)

## compose_files : files to archive for docker-compose
compose_files ?= docker-compose.yml $(wildcard README.* .env env)

## dstar_corpus : corpus name for dstar ddc-index or web instances
compose_corpus ?= CORPUS

## dstar_snapver : snapshot archive version (filename infix)
dstar_snapver ?= current

## 2025-06-11 TODO: fix/replace these old snapshot URLs

## dstar_server_snapshot : snapshot archive (local file) for dstar ddc-server instances
#dstar_server_snapshot ?= data.dwds.de:/home/ddc-dstar/dstar/snapshots/$(dstar_corpus)-server-$(dstar_snapver).tar.gz
dstar_server_snapshot ?= ../../data/$(dstar_corpus)-server-$(dstar_snapver).tar.gz

## dstar_web_snapshot : snapshot archive (local file) for dstar ddc-web instances
#dstar_web_snapshot ?= kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/$(dstar_corpus)-web-$(dstar_snapver).tar.gz
dstar_web_snapshot ?= ../../data/$(dstar_corpus)-web-$(dstar_snapver).tar.gz


##-------------------------------------------------------------
## Variables: docker volume stuff

## volume_base : volume basename
volume_base ?= $(if $(repodir:/=),$(repodir:/=-),)$(repobase)

## volume_tag : volume tag (suffix)
volume_tag ?= $(repotag)

## volume : volume basename+suffix
volume ?= $(volume_base)$(if $(volume_tag),-$(volume_tag),)

## volume_path : default volume moint point
volume_path ?= /opt/$(volume_base)

## volume_mount : default volume mount option
volume_mount ?= -v $(volume):$(volume_path)

## volume_labels : common labels (used by default 'volume-create' rule)
volume_labels ?= \
	$(labns)project.id=$(volume) \
	$(dockerlabels)

## volume_sync : sync source(s) for volume, space-separated list of ITEMs, where each ITEM is:
##  - a local .tar.gz archive PATH
##  - a remote .tar.gz archive HOST:PATH
volume_sync ?=

##-------------------------------------------------------------
## Variables: ssh stuff
##  - UPDATE (2019-10-16): prefer `env DOCKER_BUILDKIT=1 docker build --ssh default` and `RUN --mount=type=ssh ....`
##  - remember to build with `docker build --squash=true ...`
##  - see common.mak "ssh config for builds" for an example

## ssh_template : ssh template directory
##  + see common/Makefile for build rules
ssh_template ?= ../common/ssh

## ssh_hosts : hostnames to add to ssh/known_hosts 
#ssh_hosts ?= data.dwds.de svn.dwds.de kaskade.dwds.de www.dwds.de
ssh_hosts ?= cudmuncher.de

## ssh_user : ssh target username for remote hosts
#ssh_user  ?= ddc
ssh_user  ?= $(shell id -un)

## ssh_key : RSA private key to use for ssh
ssh_key ?= $(wildcard $(HOME)/.ssh/$(ssh_user)_docker_build)

##-------------------------------------------------------------
## Variables: dstar checkouts

## dstar_svnroot : svnroot for dstar checkouts
#dstar_svnroot ?= svn+ssh://odo.dwds.de/home/svn/dev/ddc-dstar/trunk
#dstar_svnroot ?= svn+ssh://svn.dwds.de/home/svn/dev/ddc-dstar/trunk
#dstar_svnroot ?= svn+ssh://cudmuncher.de/home/svn/dev/ddc-dstar/trunk
#dstar_svnroot ?= svn+ssh://mukau@svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
dstar_svnroot ?= https://svn.code.sf.net/p/ddc-dstar-core/code/ddc-dstar/trunk
export dstar_svnroot

## dstar_svnrev : svn revision for dstar checkouts
dstar_svnrev ?= HEAD
export dstar_svnrev

## dstar_svnargs : docker build args for dstar svn stuff
dstar_svnargs ?= \
	dstar_svnroot=$(dstar_svnroot) \
	dstar_svnrev=$(dstar_svnrev)

##======================================================================
## macros

##--------------------------------------------------------------
## CMDS = $(call showvar,$(varname))
define showvar
	@echo "$(strip $(1))=$($(strip $(1)))"
endef

##--------------------------------------------------------------
## ROOT = $(call svnroot,$(dir))
define svnroot
 `svn info $(if $(strip $(1)),$(1),.) | sed -ne 's/^URL: //p;'`
endef

##--------------------------------------------------------------
## EXTURL = $(call svnexturl,$(dir),$(key))
## EXTURL = $(call svnexturl,$(dir),$(key))
define svnexturl
 `svn pget svn:externals $(if $(strip $(1)),$(1),.) | perl -ne 'print if (s{^\Q$(strip $(2))\E\s*}{});'`
endef

##--------------------------------------------------------------
## NEWLINE = $(call cr)
define cr


endef

##--------------------------------------------------------------
## RULES = $(call sync_template,$(LABEL),$(SRC),$(DST),$(UNTAR))
define sync_template

sync_$(1)_label=$(1)
sync_$(1)_src=$(2)
sync_$(1)_dst=$(3)
sync_$(1)_untar=$(if $(4),$(4),tar xvz -C $(3))
ifeq ($$(words $$(subst :, ,$(2))),1)
 sync_$(1)_host=
 sync_$(1)_file=$(2)
else
 sync_$(1)_host=$$(word 1,$$(subst :, ,$(2)))
 sync_$(1)_file=$$(word 2,$$(subst :, ,$(2)))
endif


sync-$(1):
	$$(MAKE) -B $$@-src.stamp
	$$(MAKE) $$@.stamp
	rm -f $$@-src.stamp

sync-$(1).stamp: sync-$(1)-src.stamp
	$$(if $$(sync_$(1)_host),scp $(2) /dev/stdout,cat $(2)) | $$(sync_$(1)_untar)
	touch -r $$< $$@

sync-$(1)-src.stamp:
	touch -d @$$$$($$(if $$(sync_$(1)_host),ssh $$(sync_$(1)_host),) stat -c '%Y' $$(sync_$(1)_file)) $$@

sync-$(1)-config:
	$$(call showvar,sync_$(1)_src)
	$$(call showvar,sync_$(1)_host)
	$$(call showvar,sync_$(1)_file)
	$$(call showvar,sync_$(1)_dst)

endef
