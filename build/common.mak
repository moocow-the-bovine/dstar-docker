##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: dstar-docker/common.mak
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: common rules for dstar docker builds

##==============================================================
## Rules: config: show configuration

.PHONY: config
config::
	@echo "#-- $(notdir $(CURDIR)) (common) --"
	$(call showvar,docker)
	$(call showvar,imgid)
	$(call showvar,conid)
	$(call showvar,repodir)
	$(call showvar,repobase)
	$(call showvar,repotag)
	$(call showvar,repo)
	$(call showvar,tagpath)
	$(call showvar,tagas)
	$(call showvar,tagrepos)
	$(call showvar,buildid)
	$(call showvar,labns)
	$(call showvar,buildlab)
	$(call showvar,buildstages)
	$(call showvar,buildsquash)
	$(call showvar,dockerlabels)
	$(call showvar,dockerargs)
	$(call showvar,dockerbuild)
	$(call showvar,dockerrun)
	$(call showvar,distdir)
	$(call showvar,disttag)
	$(call showvar,distbase)
	$(call showvar,distfiles)
	$(call showvar,publish_dst)
	$(call showvar,publish_rsync)
	$(call showvar,dstar_template_idfile)
	$(call showvar,dstar_corpus)
	$(call showvar,dstar_snapver)
	$(call showvar,dstar_server_snapshot)
	$(call showvar,dstar_web_snapshot)
	$(call showvar,ssh_user)
	$(call showvar,ssh_key)
	$(call showvar,ssh_hosts)
	$(call showvar,subdirs)

ifeq ($(dstar_docker_no_common_help),)
.PHONY: help
help::
	@echo ""
	@echo "#-- $(notdir $(CURDIR)) (common targets) --"
	@echo "help          # this help message"
	@echo "config        # show config variables"
	@echo "build         # build docker image (img.id)"
	@echo "tag           # assign image tag(s) \$$(tagas) (default=$(tagas))"
	@echo "run           # run the docker image (con.id)"
	@echo "save          # save the current image (image.tar.gz)"
	@echo "export        # export a snapshot of a bare container (export.tar.gz)"
	@echo "dist          # update distribution file ($(distdir)/$(distbase).image.tar.gz)"
	@echo "publish       # publish distribution file to \$$(publish_dst) (=$(publish_dst))"
	@echo "dist-load     # load image from distribution file ($(distdir)/$(distbase).image.tar.gz)"
	@echo "dist-import   # import distribution image from local file"
	@echo "dist-export   # export distribution image to local file"
	@echo "prune         # remove danglign docker objects for this project"
	@echo "clean         # prune + remove local images, build files, IDs, and docker objects"
	@echo "cleaner       # clean + remove all docker objects for this project"
	@echo "realclean     # cleaner + precious files (e.g. corpus.tar.gz, web.tar.gz)"
	@echo ""
endif

##==============================================================
## Rules: build, run, tag (generic)

docker_build_opts = \
	$(buildsquash) \
	--label "$(buildlab)=$(buildid)" \
	$(patsubst %,--label "%",$(dockerlabels)) \
	$(patsubst %,--build-arg "%",$(dockerargs)) \
	$(patsubst %,--secret "%",$(dockersecrets)) \
	$(patsubst %,--ssh "%",$(dockerssh)) \
	--progress=plain \
	$(dockerbuild)

ifneq ($(wildcard Dockerfile),)
.PHONY: build
build:
	$(MAKE) img.id
img.id: Dockerfile
ifeq ($(buildstages),)
	$(docker) build --iidfile=$@ -t "$(repo)" $(docker_build_opts) .
else
	$(foreach stage,$(buildstages),\
	  $(MAKE) build-stage-$(stage)$(cr))
	$(docker) tag "$(repo)-$(word $(words $(buildstages)),$(buildstages))" "$(repo)"
	cp -af img-$(word $(words $(buildstages)),$(buildstages)).id $@
endif

build-stage-%:: Dockerfile
	$(docker) build --iidfile=img-$*.id -t "$(repo)-$*" --target=$* $(docker_build_opts) .

build-force:
	rm -f img.id
	$(MAKE) build
force-build: build-force
endif

run: con.id
con.id: img.id
	$(docker) run --cidfile=$@ `cat $<` $(dockerrun)


.PHONY: tag tag-force
tag-force: tag
tag:
	$(foreach rtag,$(tagrepos),\
	  $(docker) tag "$(repo)" "$(rtag)"$(cr))

##==============================================================
## Rules: save (image.tar.gz), dist ($(distdir)/$(project)-$(version).image.tar.gz)

.PHONY: save image
save: image.tar.gz
image: image.tar.gz
image.tar.gz: img.id
	rm -f $@ && $(docker) save `cat $<` | gzip --fast > $@

.PHONY: export
export: export.tar.gz
export.tar.gz: img.id
	$(docker) run --cidfile=export.id `cat $<` /bin/true
	rm -f $@ && $(docker) export `cat export.id` | gzip --fast > $@
	-$(docker) stop `cat export.id`
	-$(docker) rm `cat export.id`
	-rm -f export.id

.PHONY: dist image-dist dist-image
dist: $(addprefix $(distdir)/,$(distfiles))

.PHONY: image-dist dist-image
export ?= $(distdir)/$(distbase).image.tar.gz
dist-image: image-dist
image-dist: $(export)
$(export): img.id
	$(MAKE) dist-export

.PHONY: dist-export
dist-export:
	test \! -e $(export) || ( rm -i $(export) && test \! -e $(export) )
	$(docker) save "$(repopath):$(disttag)" | gzip --fast > $(export)

.PHONY: no-dist nodist
nodist: no-dist
no-dist:
	-rm -f $(distdir)/$(distbase).image.tar.gz

.PHONY: dist-force
dist-force:
	$(MAKE) no-dist && $(MAKE) dist

.PHONY: dist-load import
dist_load ?= $(distdir)/$(distbase).image.tar.gz
import: dist-load
dist-load:
	$(docker) load -i $(dist_load)

.PHONY: dist-import
dist-import:
ifeq ($(wildcard $(dist_load)),)
	@echo "dist-import: skipping non-existent $(dist_load)" >&2
else
	$(docker) load -i $(dist_load)
endif


##==============================================================
## Rules: publish

.PHONY: publish
publish: $(addprefix $(distdir:/=)/,$(distfiles))
	$(publish_rsync) $^ $(publish_dst)


##==============================================================
## Rules: push

## RECIPE = $(call do_push,SRC,DST)
define do_push
	test "$(strip $(1))" = "$(strip $(2))" || docker tag $(strip $(1)) $(strip $(2))$(cr)
	$(docker) push $(push_options) $(strip $(2))$(cr)
	test "$(strip $(1))" = "$(strip $(2))" || docker rmi $(strip $(2))$(cr)
endef

.PHONY: push
push:
	$(foreach tag,$(push_tags),$(call do_push,$(repo),$(push_repo):$(tag))$(cr))

##==============================================================
## Rules: ssh config for builds
##  + Variant 1: private build stages
##    - example Dockerfile
##      FROM debian:jessie
##      ...
##      FROM base AS private
##      ADD ssh   /root/.ssh
##      RUN svn co svn+ssh//${SVNROOT} wcopy
##      ...
##      FROM scratch AS deploy
##      COPY --from=private / /
##    - build command:
##      $ docker build [--target=deploy] .
##  + Variant 2: --squash flag ::DEPRECATED::
##    - Dockerfile:
##      FROM debian:jessie
##      ...
##      ADD ssh /root/.ssh
##      RUN svn co svn+ssh//${SVNROOT} wcopy
##      ...
##      RUN rm -rf /root/.ssh
##    - build command:
##      $ docker build --squash=true .
##  + Variant 3: use docker-squash (https://github.com/jwilder/docker-squash/)
##    - Dockerfile as for Variant 2
##    - build command(s)
##      $ docker build --squash=true -t TAG . \
##        && docker save TAG | sudo docker-squash | docker load

ifneq ($(wildcard $(ssh_template)/config),)
.PHONY: ssh
ssh: ssh/config
ssh/id_rsa: ssh/config
ssh/known_hosts: ssh/config
ssh/config: $(ssh_template)/config
	test \! -e ssh || rm -rf ssh
	cp -a $(ssh_template) ssh
endif

REALCLEAN_DIRS += ssh

##==============================================================
## Rules: clean

##--------------------------------------------------------------
## Rules: prune: remove any dangling docker objects for this project (except *.id)
.PHONY: prune prune-which

docker_ps=$(docker) ps -qaf label=$(buildlab)=$(buildid)
docker_ls=$(docker) image ls -qaf label=$(buildlab)=$(buildid)
conid=$$(cat con.id 2>/dev/null)
imgid=$$(cat img.id 2>/dev/null)

prune-which:
	@echo "$@:containers:" $$($(docker_ps) -f status=exited | grep -vx "$$($(docker) ps -qaf id=$(conid))")
	@echo "$@:images:" $$($(docker_ls) -f dangling=true)

prune:
	-ids=$$($(docker_ps) -f status=exited | grep -vx "$$($(docker) ps -qaf id=$(conid))") ; test -z "$$ids" || $(docker) rm $$ids
	-ids=$$($(docker_ls) -f dangling=true) ; test -z "$$ids" || $(docker) rmi $$ids

##--------------------------------------------------------------
## Rules: clean: prune + local images, build files, IDs, and associated docker objects
.PHONY: clean clean-which

clean-which: prune-which
	@echo "$@:files:" "$(wildcard $(CLEAN_FILES))"
	@echo "$@:dirs:" "$(wildcard $(CLEAN_DIRS))"

clean: prune
	-test \! -e con.id || $(docker) rm `cat con.id`
	-test \! -e img.id || $(docker) rmi `cat img.id`
	-test -z "$(CLEAN_FILES)" || rm -f $(CLEAN_FILES)
	-test -z "$(CLEAN_DIRS)" || rm -rf $(CLEAN_DIRS)

##--------------------------------------------------------------
## Rules: cleaner: clean + all docker objects tagged for this project
##  + aliases: dockerclean, dclean
.PHONY: cleaner dockerclean dclean cleaner-which

dclean: cleaner
dockerclean: cleaner

cleaner-which:
	@echo "$@:containers:" $$($(docker_ps))
	@echo "$@:images:" $$($(docker_ls))
	@echo "$@:files:" "$(wildcard $(CLEANER_FILES))"
	@echo "$@:dirs:" "$(wildcard $(CLEANER_DIRS))"

cleaner: clean
	-ids=$$($(docker_ps)) ; test -z "$$ids" || $(docker) rm $$ids
	-ids=$$($(docker_ls)) ; test -z "$$ids" || $(docker) rmi $$ids
	-test -z "$(CLEANER_FILES)" || rm -f $(CLEANER_FILES)
	-test -z "$(CLEANER_DIRS)" || rm -rf $(CLEANER_DIRS)

##--------------------------------------------------------------
## Rules: realclean: cleaner + "precious" local files (e.g. persistent corpus index snapshots)
.PHONY: realclean realclean-which
realclean: cleaner

realclean-which:
	@echo "$@:containers:" $$($(docker_ps))
	@echo "$@:images:" $$($(docker_ls))
	@echo "$@:files:" "$(wildcard $(REALCLEAN_FILES))"
	@echo "$@:dirs:" "$(wildcard $(REALCLEAN_DIRS))"

realclean: cleaner
	-ids=$$($(docker_ps)) ; test -z "$$ids" || $(docker) rm $$ids
	-ids=$$($(docker_ls)) ; test -z "$$ids" || $(docker) rmi $$ids
	-test -z "$(REALCLEAN_FILES)" || rm -f $(REALCLEAN_FILES)
	-test -z "$(REALCLEAN_DIRS)" || rm -rf $(REALCLEAN_DIRS)
