##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: docker/dstar-all-nhess/Makefile
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: Makefile for dstar docker-compose bundle: nhess

##==============================================================
## Configuration

## docker-compose environment
include ./.env

## repotag : image repsitory tag
repotag ?= $(SNAPSHOT)

## common configuration
include ../config.mak

## compose_files : additional stuff to distribute
compose_files += conf.d init.d

##==============================================================
## Rules: top-level
all: help

##==============================================================
## Rules: common (compose)
include ../compose.mak
