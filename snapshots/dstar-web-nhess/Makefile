##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-web-nhess/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for dstar-cabx docker volume: web: nhess

##==============================================================
## Configuration

##-- snapshot version
#dstar_snapver=2017-09-26
#dstar_snapver=2018-10-24
#dstar_snapver=2019-10-16
dstar_snapver=2020-10-05

##-- repotag : image repsitory tag
repotag ?= $(dstar_snapver)

##-- volume configuration
#volume_base ?= $(notdir $(CURDIR))
volume_tag  ?= $(repotag)
volume_sync ?= \
	$(firstword \
	  $(wildcard ../../data/nhess-web-$(dstar_snapver).tar.gz) \
	  kaskade.dwds.de:/home/ddc-dstar/dstar/snapshots/nhess-web-$(dstar_snapver).tar.gz)

## common configuration
include ../config.mak


##==============================================================
## Rules: top-level
all: volume


##==============================================================
## Rules: common (volumes)
include ../volume.mak
