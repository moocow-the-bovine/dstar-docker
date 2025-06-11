##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-ddc-nhess/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for dstar-cabx docker volume: ddc index: nhess

##==============================================================
## Configuration

##-- dta2017
#dstar_snapver=2017-09-26

##-- snapshot version
#dstar_snapver=2018-10-24
#dstar_snapver=2019-10-16
dstar_snapver=2020-10-05
volume_sync=../../data/nhess-server-$(dstar_snapver).tar.gz

##-- repotag : image repsitory tag
repotag ?= $(dstar_snapver)

##-- volume configuration
#volume_base ?= $(notdir $(CURDIR))
volume_tag  ?= $(repotag)
volume_sync ?= \
	data.dwds.de:/home/ddc-dstar/dstar/snapshots/nhess-server-$(dstar_snapver).tar.gz

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

##-- fix bogus /mnt/SSD/ddc-dstar/dstar/config/
include ../dstar-ddc-dta/hack2020.mak
