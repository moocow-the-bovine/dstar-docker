##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: dstar-docker/compose.mak
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: common rules for dstar docker-compose builds

##==============================================================
## Rules: config: show configuration

.PHONY: config
config::
	@echo "#-- $(notdir $(CURDIR)) (common) --"
	$(call showvar,docker)
	$(call showvar,docker_compose)
	$(call showvar,repodir)
	$(call showvar,repobase)
	$(call showvar,repotag)
	$(call showvar,repo)
	$(call showvar,compose_project)
	$(call showvar,compose_files)
	$(call showvar,dstar_corpus)
	$(call showvar,dstar_snapver)
	$(call showvar,dstar_server_snapshot)
	$(call showvar,dstar_web_snapshot)
	$(call showvar,distdir)
	$(call showvar,distbase)

.PHONY: help
help::
	@echo ""
	@echo "#-- $(notdir $(CURDIR)) : common targets"
	@echo "help          # this help message"
	@echo "config        # show config variables"
	@echo "#"
	@echo "#-- $(notdir $(CURDIR)) : docker-compose wrappers"
	@echo "up            # wraps docker-compose up"
	@echo "up-d          # wraps docker-compose up -d"
	@echo "down          # wraps docker-compose down"
	@echo "cconfig       # wraps docker-compose config"
	@echo "...           # docker-compose {logs,logs-f,build,ps,start,stop,restart,pause,unpause,rm,rm-f,version}"
	@echo "#"
	@echo "#-- $(notdir $(CURDIR)) : packaging & distribution"
	@echo "distdir       # prepare local distribution directory"
	@echo "dist          # update distribution file ($(distdir)/$(distbase).compose.tar.gz)"
	@echo "#"
	@echo "#-- $(notdir $(CURDIR)) : cleanup"
	@echo "prune         # remove dangling docker containers for this project"
	@echo "clean         # prune + remove local build files"
	@echo "cleaner       # clean + remove all docker objects for this project"
	@echo "realclean     # cleaner + remove all docker objects for this project"
	@echo ""


##==============================================================
## Rules: compose: create/up/down/restart

## CODE = $(call docker_compose_template,ALIAS,ARGS...)
define docker_compose_template
.PHONY: $(1)
$(1):
	$$(docker_compose) $(if $(strip $(2)),$(2),$(1))
endef

## CODE = $(call docker_compose_ptemplate,ALIAS,ARGS...)
##  + prepends "-p $(compose_project)" option
define docker_compose_ptemplate
.PHONY: $(1)
$(1):
	$$(docker_compose) -p $$(compose_project) $(if $(strip $(2)),$(2),$(1))
endef


$(eval $(call docker_compose_ptemplate,up))
$(eval $(call docker_compose_ptemplate,up-d,up -d))
upd: up-d

$(eval $(call docker_compose_ptemplate,down))

$(eval $(call docker_compose_ptemplate,logs))
$(eval $(call docker_compose_ptemplate,logs-f,logs -f))

compose-config: cconfig
$(eval $(call docker_compose_template,cconfig,config))

##-- other commands: project-sensitive
$(foreach cmd, build ps start stop restart rm pause unpause,\
	$(eval $(call docker_compose_ptemplate,$(cmd))))
$(eval $(call docker_compose_ptemplate,rm-f,rm -f))

##-- other commands: generic
$(foreach cmd, version,\
	$(eval $(call docker_compose_template,$(cmd))))


##==============================================================
## Rules: compose: dist ($(distdir)/$(project)-$(version).compose.tar.gz)

.PHONY: distdir
distdir:: $(compose_files)
	rm -rf $(distbase)
	mkdir $(distbase)
	cp -al $(compose_files) $(distbase)/
CLEAN_DIRS += $(distbase)

.PHONY: dist
dist: $(distdir)/$(distbase).compose.tar.gz
$(distdir)/$(distbase).compose.tar.gz:
	test \! -e $@ || (rm -i $@ && test \! -e $@)
	$(MAKE) distdir
	tar c $(distbase) | gzip --fast > $@
	rm -rf $(distbase)

no-dist:
	rm -f $(distdir)/$(distbase).compose.tar.gz
nodist: no-dist

##==============================================================
## Rules: compose: publish

.PHONY: publish
publish: $(distdir)/$(distbase).compose.tar.gz
	$(publish_rsync) $^ $(publish_dst)

##==============================================================
## Rules: clean

##--------------------------------------------------------------
## Rules: prune: remove any dangling docker objects for this project (except *.id)
.PHONY: prune prune-which

docker_ps=$(docker) ps -qaf name='$(compose_project)_*'

prune-which:
	@echo "$@:containers:" $$($(docker_ps) -f status=exited)

prune:
	-ids=$$($(docker_ps) -f status=exited) ; test -z "$$ids" || $(docker) rm $$ids

##--------------------------------------------------------------
## Rules: clean: prune + local images, build files, IDs, and associated docker objects
.PHONY: clean clean-which

clean-which:: prune-which
	@echo "$@:files:" "$(wildcard $(CLEAN_FILES))"
	@echo "$@:dirs:" "$(wildcard $(CLEAN_DIRS))"

clean:: prune
	-test -z "$(CLEAN_FILES)" || rm -f $(CLEAN_FILES)
	-test -z "$(CLEAN_DIRS)" || rm -rf $(CLEAN_DIRS)


##--------------------------------------------------------------
## Rules: cleaner: prune + clean + ??
##  + aliases: dockerclean, dclean
.PHONY: cleaner dockerclean dclean cleaner-which

dclean: cleaner
dockerclean: cleaner

cleaner-which::
	@echo "$@:containers:" $$($(docker_ps))
	@echo "$@:files:" "$(wildcard $(CLEANER_FILES))"
	@echo "$@:dirs:" "$(wildcard $(CLEANER_DIRS))"

cleaner:: clean
	-ids=$$($(docker_ps)) ; test -z "$$ids" || $(docker) rm $$ids
	-test -z "$(CLEANER_FILES)" || rm -f $(CLEANER_FILES)
	-test -z "$(CLEANER_DIRS)" || rm -rf $(CLEANER_DIRS)

##--------------------------------------------------------------
## Rules: realclean: cleaner + "precious" local files (e.g. persistent corpus index snapshots)
.PHONY: realclean realclean-which

realclean-which::
	@echo "$@:containers:" $$($(docker_ps))
	@echo "$@:files:" "$(wildcard $(REALCLEAN_FILES))"
	@echo "$@:dirs:" "$(wildcard $(REALCLEAN_DIRS))"

realclean:: cleaner
	-ids=$$($(docker_ps)) ; test -z "$$ids" || $(docker) rm $$ids
	-test -z "$(REALCLEAN_FILES)" || rm -f $(REALCLEAN_FILES)
	-test -z "$(REALCLEAN_DIRS)" || rm -rf $(REALCLEAN_DIRS)
