##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-web-dta/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for dstar-cabx docker volume: web: dta

##==============================================================
## Configuration

##-- snapshot version
#dstar_snapver=2017-09-27
#dstar_snapver=2018-10-29
#dstar_snapver=2019-10-16
dstar_snapver=2020-10-05

##-- repotag : image repsitory tag
repotag ?= $(dstar_snapver)

##-- volume configuration
#volume_base ?= $(notdir $(CURDIR))
volume_tag  ?= $(repotag)
volume_sync ?= $(firstword \
	$(wildcard $(addsuffix dta-web-$(dstar_snapver).tar.gz, ../../data/ $(HOME)/dstar/snapshots/)) \
	kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/dta-web-$(dstar_snapver).tar.gz \
	)

## common configuration
include ../config.mak


##==============================================================
## Rules: top-level
all: volume


##==============================================================
## Rules: common (volumes)
include ../volume.mak

##==============================================================
## Rules: local hacks

##-- fix missing config/web/dta_.*
include ../dstar-ddc-dta/hack2020.mak
