##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/common/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for docker images: common stuff

##======================================================================
## Configuration

## repotag : image repsitory tag
#repotag ?= 42

include ../config.mak

##======================================================================
## Rules: top-level
all: ssh

##--------------------------------------------------------------
## Rules: local: ssh

ssh_template :=

.PHONY: ssh
ssh: ssh/config
ssh/id_rsa: ssh/config
ssh/known_hosts: ssh/config
ssh/config: ssh.template/config
	cp -aT ssh.template ssh
	chmod 0700 ssh
	chmod -R go-w ssh

REALCLEAN_DIRS += ssh

##==============================================================
## Rules: common
push_tags :=
include ../common.mak
