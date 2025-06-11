##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/ddc/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for ddc docker image

##==============================================================
## DEBUG overrides

repobase = dstar-base
repotag  = buster
#buildsquash :=

##==============================================================
## Configuration

## repotag : image repsitory tag for build
#repotag ?= 2017-0

## dockerargs : common --build-arg options (used by default 'build' rule)
dockerargs = $(dstar_svnargs)

## tagas : post-build tag(s), also default $(disttag)
#tagas ?= 2017-09-27

## buildstages : build stages (empty for single-FROM build)
#buildstages = base private deploy

## common configuration
include ../config.mak

##==============================================================
## Rules: top-level
all:
	$(MAKE) -C ../common
	$(MAKE) build
	$(MAKE) tag

##==============================================================
## Rules: build: local

img.id: packages.txt ssh/config

##==============================================================
## Rules: common
include ../common.mak
