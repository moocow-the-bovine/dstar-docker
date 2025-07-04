##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/build/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker images: top-level

##======================================================================
## Configuration

## common configuration
push_enabled := no
tag_enabled := no
include config.mak

## tasks
tasks ?= base

## task-wise subdirectories
base_dirs   = common dstar-base dstar-runhost dstar-webhost dstar-buildhost dstar-rcbuildhost

## subdirectories
subdirs ?= $(base_dirs)

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
$(call alias_template,$(1),push)
$(call alias_template,$(1),tag)
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
dstar-buildhost/.all: $(call dstar_subdep,dstar-webhost)
dstar-rcbuildhost/.all: $(call dstar_subdep,dstar-buildhost)

##======================================================================
## Rules: common
dstar_docker_no_common_help=1
include common.mak
