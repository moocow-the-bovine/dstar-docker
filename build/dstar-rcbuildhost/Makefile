##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-rcbuildhost/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker dstar-rcbuildhost image

##==============================================================
## DEBUG

#repobase = dstar-rcbuildhost
repotag  = buster
#buildsquash :=

##==============================================================
## Configuration

## repotag : image repsitory tag for build
#repotag ?= 2017-0

## tagas : post-build tag(s), also default $(disttag)
#tagas ?= 2017-09-27

## push_tags : tags to be pushed # # # (empty to suppress push)
push_tags =

## common configuration
include ../config.mak

REALCLEAN_DIRS += dstar

##==============================================================
## Rules: top-level
all:
	$(MAKE) build
	$(MAKE) tag

##==============================================================
## Rules: local

img.id: ../dstar-buildhost/img.id packages.txt ssh.private/config
#cpanm.txt
#ssh/config
#dstar-web-run.sh

##-- ssh.private: obfuscate cudmuncher ssh config
ssh: ssh.private
ssh.private: ssh.private/config
ssh.private/config: ssh/config
	mkdir -p $(dir $@)
	cp $< $@
	echo -e "\n##-- cudmuncher" >>$@
	sed -n '/^Host cudmuncher\.de/,/^$$/{ /Host/p; /Port/p; /User/p; }' ~/.ssh/config >>$@
	sed -n '/^Host cudmuncher\.de/,/^$$/p' $@ | grep User || echo -e " User $(shell id -un)" >>$@

REALCLEAN_DIRS += ssh.private

##==============================================================
## Rules: common
include ../common.mak
