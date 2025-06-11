##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-all-dta/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for dstar docker-compose bundle: dta

##==============================================================
## Configuration

## docker-compose environment
include ./.env

## tagas : tags for dist
tagas ?= $(SNAPSHOT)

## common configuration
include ../config.mak

## compose_files : additional stuff to distribute
compose_files += conf.d init.d

##==============================================================
## Rules: top-level
all: help

##==============================================================
## Rules: local

.PHONY: install-sysv install-systemd install
install: install-sysv install-systemd

install-sysv: dta2020.sh
	ln -sf $(CURDIR)/dta2018.sh /etc/init.d/dta2020
#	install -m 0755 -p -v sysv.sh     /etc/init.d/dta2020
#	update-rc.d dta2020 defaults

install-systemd: dta2020.service
	install -m 0644 -p -v dta2020.service      /etc/systemd/system/dta2020.service
	/bin/systemctl daemon-reload
	/bin/systemctl reenable dta2020.service

##==============================================================
## Rules: common (compose)
include ../compose.mak
