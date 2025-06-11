##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker images: top-level

##======================================================================
## Configuration

## common configuration
include config.mak

## tasks
tasks ?= \
	base \
	nhess \
	dta

## task-wise subdirectories
base_dirs   = common dstar-base dstar-runhost dstar-webhost
nhess_dirs = dstar-cab-en dstar-ddc-nhess dstar-web-nhess
dta_dirs   = dstar-cab-de dstar-cab-dta $(foreach c,dtak dtae dta,dstar-ddc-$(c) dstar-web-$(c))

## subdirectories
subdirs ?= \
	$(base_dirs) \
	$(nhess_dirs) \
	$(dta_dirs)

##======================================================================
## Rules: top-level
all: $(subdirs:=/.all)

##======================================================================
## Rules: help

dstar_docker_no_common_help=1
help::
	@echo ""
	@echo "#-- $(notdir $(CURDIR)) : top-level targets --"
	@echo "help          # this help message"
	@echo "config        # top-level config"
	@echo "all           # batch 'make all'"
	@echo "build         # batch 'make build'"
	@echo "build-force   # batch 'make build-force'"
	@echo "dist          # batch 'make dist'"
	@echo "dist-import   # batch 'make dist-import'"
	@echo "dist-export   # batch 'make dist-export'"
	@echo "prune         # batch 'make prune'"
	@echo "clean         # batch 'make clean'"
	@echo "cleaner       # batch 'make cleaner'"
	@echo "realclean     # batch 'make realclean'"
	@echo ""

config::
	@echo "#-- $(notdir $(CURDIR)) (top-level) --"
	$(call showvar,tasks)
	$(foreach t,$(tasks),\
	  $(call showvar,$(t)_dirs)$(cr))
	$(call showvar,subdirs)


##======================================================================
## Rules: tasks

## CODE = $(call task_template,$(task))
define task_template
.PHONY: $(1)
$(1): $$($(1)_dirs:=/.all)
endef
$(foreach task,$(tasks),$(eval $(call task_template,$(task))))

##======================================================================
## Rules: subdirs

## CODE = $(call alias_template,$(subdir),$(alias),$(target))
define alias_template
$(2): $(1)/.$(2)
$(1)/.$(2):
	$$(MAKE) -C $(1) $(if $(3),$(3),$(2))

endef

## CODE = $(call subdir_template,$(subdir))
define subdir_template
$(call alias_template,$(1),all)
$(call alias_template,$(1),build)
$(call alias_template,$(1),build-force)
$(call alias_template,$(1),dist)
$(call alias_template,$(1),dist-import)
$(call alias_template,$(1),dist-export)
$(call alias_template,$(1),prune)
$(call alias_template,$(1),clean)
$(call alias_template,$(1),cleaner)
$(call alias_template,$(1),realclean)
endef
$(foreach subdir,$(subdirs),$(eval $(call subdir_template,$(subdir))))

##--------------------------------------------------------------
## Rules: subdirs: deps

define dstar_subdep
 $(addsuffix /.all,$(filter $(1),$(subdirs)))
endef

dstar-runhost/.all: $(call dstar_subdep,dstar-base)
dstar-webhost/.all: $(call dstar_subdep,dstar-runhost)

dstar-cab-en/.all: $(call dstar_subdep,dstar-base)
dstar-cab-de/.all: $(call dstar_subdep,dstar-base)
dstar-cab-dta/.all: $(call dstar_subdep,dstar-base)

dstar-ddc-nhess/.all: $(call dstar_subdep,dstar-base)
dstar-ddc-dta/.all: $(call dstar_subdep,dstar-base)

dstar-web-nhess/.all: $(call dstar_subdep,dstar-base)
dstar-web-dta/.all: $(call dstar_subdep,dstar-base)

dstar-all-nhess/.all: $(call dstar_subdep,dstar-webhost dstar-cab-en dstar-ddc-nhess dstar-web-nhess)
dstar-all-dta/.all: $(call dstar_subdep,dstar-webhost dstar-cab-dta dstar-cab-de dstar-ddc-dta dstar-web-dta)

##======================================================================
## Rules: common
dstar_docker_no_common_help=1
include common.mak
