##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/snapshots/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker images: snapshots

##======================================================================
## Configuration

## tasks
tasks ?= base

## task-wise subdirectories
nhess_dirs = dstar-cab-en dstar-ddc-nhess dstar-web-nhess
dta_dirs   = dstar-cab-de dstar-cab-dta $(foreach c,dtak dtae dta,dstar-ddc-$(c) dstar-web-$(c))

## subdirectories
subdirs ?= $(nhess_dirs) $(dta_dirs)

## inherited rules etc.
include ../build/Makefile

##======================================================================
## Rules: subdirs
$(foreach subdir,$(subdirs),$(eval $(call subdir_template,$(subdir))))

##--------------------------------------------------------------
## Rules: subdirs: deps

define dstar_subdep
 $(addsuffix /.all,$(filter $(1),$(subdirs)))
endef

dstar-all-nhess/.all: $(call dstar_subdep,dstar-cab-en dstar-ddc-nhess dstar-web-nhess)
dstar-all-dta/.all: $(call dstar_subdep,dstar-cab-dta dstar-cab-de dstar-ddc-dta dstar-web-dta)
