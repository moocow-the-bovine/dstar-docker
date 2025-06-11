##-*- Mode: GNUmakefile; coding: utf-8; -*-
##
## File: dstar-docker/volume.mak
## Author: Bryan Jurish <jurish@bbaw.de>
## Description: common rules for dstar docker volume builds

##==============================================================
## Rules: config: show configuration

.PHONY: config
config::
	@echo "#-- $(notdir $(CURDIR)) (common) --"
	$(call showvar,docker)
	$(call showvar,volume_base)
	$(call showvar,volume_tag)
	$(call showvar,volume)
	$(call showvar,volume_path)
	$(call showvar,volume_mount)
	$(call showvar,volume_labels)
	$(call showvar,volume_sync)
	$(call showvar,distdir)
	$(call showvar,distbase)

.PHONY: help
help::
	@echo ""
	@echo "#-- $(notdir $(CURDIR)) : common targets"
	@echo "help          # this help message"
	@echo "config        # show config variables"
	@echo "#"
	@echo "#-- $(notdir $(CURDIR)) : volume operations"
	@echo "volume        # create & populate volume from \$$(volume_sync) source(s)"
	@echo "volume-create # create volume (no sync)"
	@echo "volume-sync   # synchronize volume from \$$(volume_sync) source(s)"
	@echo "volume-rm     # remove volume"
	@echo "volume-ls     # list volume(s) for current \$$(volume_base)"
	@echo "volume-ll     # list files in current volme (via find)"
	@echo "volume-exists # fails unless current volume exists"
	@echo "#"
	@echo "#-- $(notdir $(CURDIR)) : packaging & distribution"
	@echo "dist          # update distribution file ($(distdir)/$(distbase).compose.tar.gz)"
	@echo "dist-import   # force-import from distribution file"
	@echo "dist-export   # force-export to distribution file"
	@echo "import        # populate volume from a single archive (make import=TGZ import)"
	@echo "#"
	@echo "#-- $(notdir $(CURDIR)) : cleanup"
	@echo "prune         # remove dangling stale docker volumes for this project"
	@echo "clean         # prune + remove local build files"
	@echo "cleaner       # clean + remove all docker volumes for this project"
	@echo "realclean     # cleaner + precious local file(s)"
	@echo ""

##==============================================================
## Rules: top-level aliases (create & sync)

.PHONY: build
build: volume

##==============================================================
## Rules: volume operations

.PHONY: volume-create
volume-create:
	$(docker) volume create $(patsubst %,--label "%",$(volume_labels)) $(volume)

.PHONY: volume-rm volume-delete volume-remove
volume-delete: volume-rm
volume-remove: volume-remove
volume-rm:
	rm -f volume.stamp sync-*.stamp
	$(docker) volume rm $(volume)

.PHONY: volume-ls
volume-ls:
	$(docker) volume ls -f name="$(volume_base)$(if $(volume_tag),-*,)"

.PHONY: volume-inspect
volume-inspect:
	$(docker) volume inspect $(volume)

.PHONY: volume-ll
volume-ll:
	$(docker) run --rm $(volume_mount) dstar-base find $(volume_path) -ls

.PHONY: volume-exists
volume-exists:
	$(docker) volume inspect $(volume) >/dev/null

.PHONY: volume volume.stamp
volume: volume.stamp
volume.stamp:
	$(MAKE) volume-exists || ( $(MAKE) volume-create && $(MAKE) volume-sync && touch $@ )

##==============================================================
## Rules: build: sync

volume-sync::
define volume_sync_template
volume-sync:: sync-$$(notdir $(1))

$(call sync_template,$$(notdir $(1)),$(1),.,$$(docker) run -i --rm $$(volume_mount) dstar-base tar xz -C $$(volume_path))
endef

$(foreach src,$(volume_sync),$(eval $(call volume_sync_template,$(src))))


##==============================================================
## Rules: volume: dist ($(distdir)/$(distbase).volume.tar.gz)

.PHONY: dist
export ?= $(distdir)/$(distbase).volume.tar.gz
dist: $(export)
$(export): volume.stamp
	test \! -e $@ || ( rm -i $@ && test \! -e $@ )
	$(MAKE) dist-export

.PHONY: dist-export
dist-export:
	$(docker) run --rm $(volume_mount) dstar-base tar c -C $(volume_path) . | gzip --fast > $(export)


no-dist:
	rm -f $(export)
nodist: no-dist

##==============================================================
## Rules: volume: publish (via dist)

publish_src ?= $(distdir)/$(distbase).volume.tar.gz

.PHONY: publish publish-rsync
publish: $(publish_src)
	$(MAKE) publish-rsync

publish-rsync:
	$(publish_rsync) $(publish_src) $(publish_dst)

##--------------------------------------------------------------
## Rules: volume: import from $(import), default=$(distdir)/$(distbase).volume.tar.gz

.PHONY: import
import ?= $(distdir)/$(distbase).volume.tar.gz
ifeq ($(import),)
import:
	@echo "import: no archive to import; call as make import=ARCHIVE import"
	false
else
import:
	test -e $(import) || (echo "import: no source archive $(import) found" >&2; false)
	-$(MAKE) volume-rm
	$(MAKE) volume-create
	$(docker) run --rm $(volume_mount) -v $(abspath $(import)):/import.tar.gz:ro -w $(volume_path) dstar-base tar xvzf /import.tar.gz
endif

.PHONY: dist-import
dist-import: import

##==============================================================
## Rules: clean

##--------------------------------------------------------------
## Rules: prune: remove any dangling docker objects for this volume
.PHONY: prune prune-which

docker_vols=$(docker) volume ls -qf name='$(volume_base)$(if $(volume_tag),-*,)'

prune-which:
	@echo "$@:volumes:" $$($(docker_vols) -f dangling=true | grep -v '^$(volume)$$')

prune:
	-vols=$$($(docker_vols) -f dangling=true | grep -v '^$(volume)$$') ; test -z "$$vols" || $(docker) volume rm $$vols

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
## Rules: cleaner: prune + clean + current volume
##  + aliases: dockerclean, dclean
.PHONY: cleaner dockerclean dclean cleaner-which

dclean: cleaner
dockerclean: cleaner

cleaner-which:: clean-which
	@echo "$@:volumes:" $$($(docker_vols))
	@echo "$@:files:" "$(wildcard $(CLEANER_FILES))"
	@echo "$@:dirs:" "$(wildcard $(CLEANER_DIRS))"

cleaner:: clean
	-vols=$$($(docker_vols)) ; test -z "$$vols" || $(docker) volume rm $$vols
	-test -z "$(CLEANER_FILES)" || rm -f $(CLEANER_FILES)
	-test -z "$(CLEANER_DIRS)" || rm -rf $(CLEANER_DIRS)

##--------------------------------------------------------------
## Rules: realclean: cleaner + "precious" local files
.PHONY: realclean realclean-which

realclean-which:: cleaner-which
	@echo "$@:files:" "$(wildcard $(REALCLEAN_FILES))"
	@echo "$@:dirs:" "$(wildcard $(REALCLEAN_DIRS))"

realclean:: cleaner
	-test -z "$(REALCLEAN_FILES)" || rm -f $(REALCLEAN_FILES)
	-test -z "$(REALCLEAN_DIRS)" || rm -rf $(REALCLEAN_DIRS)
