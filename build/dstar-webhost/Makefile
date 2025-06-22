##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-web/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker dstar-web base

##==============================================================
## DEBUG

#repobase = dstar-runhost
repotag  = bookworm
#buildsquash :=

##==============================================================
## Configuration

## repotag : image repsitory tag for build
#repotag ?= 2017-0

## tagas : post-build tag(s), also default $(disttag)
#tagas ?= 2017-09-27

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

img.id: ../dstar-runhost/img.id packages.txt cpanm.txt
#ssh/config
#dstar-web-run.sh

##--------------------------------------------------------------
## Rules: local: (nothing here)

##==============================================================
## Rules: common
include ../common.mak
