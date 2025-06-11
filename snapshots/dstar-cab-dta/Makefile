##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-cab-de/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for dstar-cabx docker volume: de-dstar

##==============================================================
## Configuration

##-- snapshot version
#dstar_cabrc_snapver=2017-09-27
#dstar_cabrc_snapver=2018-10-29
#dstar_cabrc_snapver=2019-10-16
dstar_cabrc_snapver=2020-10-05

##-- repotag : image repsitory tag
repotag ?= $(dstar_cabrc_snapver)

##-- volume configuration
#volume_base ?= $(notdir $(CURDIR))
volume_tag  ?= $(repotag)
volume_sync ?= \
	$(foreach lg,generic de dta,\
	  $(firstword \
	    $(wildcard ../../data/cabrc-$(lg)-$(dstar_cabrc_snapver).tar.gz) \
	    data.dwds.de:/home/ddc-dstar/dstar/snapshots/cabrc-$(lg)-$(dstar_cabrc_snapver).tar.gz))

## common configuration
include ../config.mak


##==============================================================
## Rules: top-level
all: volume


##==============================================================
## Rules: common (volumes)
include ../volume.mak
