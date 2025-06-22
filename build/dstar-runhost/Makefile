##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-runhost/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker dstar-runhost

##==============================================================
## DEBUG

#repobase = dstar-runhost
#repotag  = buster
repotag  = bookworm
#buildsquash :=

##==============================================================
## Configuration

## dockerargs : common --build-arg options (used by default 'build' rule)
#dockerargs ?= $(dstar_svnargs)

## buildstages : build stages (empty for single-FROM build)
#buildstages ?= base private build run

## tagas : post-build tag(s), also default $(disttag)
#tagas ?= 2017-09-27

## common configuration
include ../config.mak


REALCLEAN_DIRS += ssh

##==============================================================
## Rules: top-level
all:
	$(MAKE) build
	$(MAKE) tag

img.id: ../dstar-base/img.id packages.txt cpanm.txt
#svnco.sh
#ssh/config

##==============================================================
## Rules: common
include ../common.mak
