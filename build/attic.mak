##==============================================================
## Rules: dstar corpus checkouts : OBSOLETE

##--------------------------------------------------------------
## Rules: dstar checkouts: generic: NEW

.PHONY: dstar-template
dstar-template: dstar-template.stamp
dstar-template.stamp: $(dstar_template_idfile)
	test \! -d dstar || rm -rf dstar
	$(docker) run --rm -w /home/ddc-dstar `cat $<` tar c dstar | tar x
	-svn upgrade dstar
	touch $@

##--------------------------------------------------------------
## Rules: dstar checkouts: corpora/$(dstar_corpus)/server

##-- dstar-corpus-server: checkout dstar/corpora/$(dstar_corpus)/server
.PHONY: dstar-server
dstar-server: dstar-server.stamp
dstar-server.stamp: dstar-template.stamp
	rm -rf dstar/corpora/$(dstar_corpus)
	svn co -r$(dstar_svnrev) -N $(dstar_svnroot)/corpus dstar/corpora/$(dstar_corpus)
	svn up -r$(dstar_svnrev) --set-depth=infinity dstar/corpora/$(dstar_corpus)/server
	svn up -r$(dstar_svnrev) --set-depth=infinity dstar/config/corpus/$(dstar_corpus).mak
	svn up -r$(dstar_svnrev) --set-depth=infinity dstar/config/opt/ddc_server.opt
	touch $@

##-- dstar-server-clone: make -C dstar/corpora/$(dstar_corpus)/server init-clone
.PHONY: dstar-server-clone
dstar-server-clone: dstar-server-clone.stamp
dstar-server-clone.stamp: dstar-server.stamp
	make -C dstar/corpora/$(dstar_corpus)/server SERVER_CLONE=$(dstar_clone) init-clone
	touch $@

##-- corpus: corpus archive (snapshot, only generated once by make rules -- after that must be manually updated)
.PHONY: corpus corpus-force
corpus: corpus.tar.gz

ifeq ($(wildcard corpus.tar.gz),)
corpus.tar.gz: dstar-server-clone.stamp
	test \! -e $@ || rm -i $@
	tar c \
	 dstar/corpora/$(dstar_corpus) \
	 dstar/config/corpus/$(dstar_corpus).mak \
	 dstar/config/opt/ddc_server.opt \
	 | gzip --fast > $@
endif

force-corpus: corpus-force
corpus-force:
	test \! -e corpus.tar.gz || rm -f corpus.tar.gz
	$(MAKE) corpus.tar.gz

##-- dist-corpus : saves corpus.tar.gz snapshot
.PHONY: corpus-dist
corpus-dist: $(distdir)/$(distbase).corpus.tar.gz
$(distdir)/$(distbase).corpus.tar.gz: corpus.tar.gz
	test \! -e $@ || rm -i $@
	ln $< $@

.PHONY: corpus-dist-force
corpus-dist-force:
	$(MAKE) no-corpus-dist && $(MAKE) corpus-dist

no-corpus-dist:
	-rm -f $(distdir)/$(distbase).corpus.tar.gz

##--------------------------------------------------------------
## Rules: dstar checkouts: resources (cabrc)

##-- dstar-cabrc: checkout & sync dstar/resources/$(dstar_cabrc)/ directory(ies)
.PHONY: dstar-cabrc dstar-cabrc-all
dstar-cabrc: dstar-cabrc-all.stamp
dstar-cabrc-all: dstar-cabrc-all.stamp
dstar-cabrc-all.stamp: $(addprefix dstar-cabrc-,$(dstar_cabrc:=.stamp)) dstar-cabrc-version.stamp
	touch $@

dstar-cabrc-version.stamp: dstar-template.stamp
	test \! -d dstar/resources || $(MAKE) -C dstar/resources HOST=docker CABRC_FILES="version.txt" sync
	touch $@

dstar-cabrc-%.stamp: dstar-template.stamp
	rm -rf dstar/resources/$*
	svn up -r$(dstar_svnrev) --set-depth=empty dstar/resources/$*
	test \! -d dstar/resources || $(MAKE) -C dstar/resources HOST=docker CABRC_FILES="$*/" sync
	touch $@

ifeq ($(wildcard cabrc.tar.gz),)
cabrc.tar.gz: dstar-cabrc-all.stamp dstar-cabxrc-all.stamp
	test \! -e $@ || rm -i $@
	tar c \
	  $(addprefix dstar/resources/,$(dstar_cabrc) version.txt) \
	  $(addprefix dstar/cabx/,$(dstar_cabxrc:=.*)) \
	  | gzip --fast >$@
endif
REALCLEAN_FILES += cabrc.tar.gz

.PHONY: cabrc-force
cabrc-force:
	test \! -e cabrc.tar.gz || rm -f cabrc.tar.gz
	$(MAKE) cabrc.tar.gz

.PHONY: cabrc-dist
dist-cabrc: cabrc-dist
cabrc-dist: $(distdir)/$(distbase).cabrc.tar.gz
$(distdir)/$(distbase).cabrc.tar.gz: cabrc.tar.gz
	test \! -e $@ || rm -i $@
	ln $< $@

##--------------------------------------------------------------
## Rules: dstar checkouts: cab expanders (cabx)

##-- dstar-cabx-rc: checkout dstar/cabx/$(dstar_cabxrc).* config file(s)
.PHONY: dstar-cabxrc dstar-cabxrc-all
dstar-cabxrc: dstar-cabxrc-all.stamp
dstar-cabxrc-all: dstar-cabxrc-all.stamp
dstar-cabxrc-all.stamp: $(addprefix dstar-cabxrc-,$(dstar_cabxrc:=.stamp))
	touch $@
dstar-cabxrc-%.stamp: dstar-template.stamp
	cd dstar/cabx && svn up -r$(dstar_svnrev) --set-depth=infinity $$(svn ls -r$(dstar_svnrev) . | grep -P '^\Q$*\E\.')
	touch $@

##--------------------------------------------------------------
## Rules: dstar checkouts: corpora/$(dstar_corpus)/web

##-- dstar-web: checkout dstar/corpora/$(dstar_corpus)/web
.PHONY: dstar-web
dstar-web: dstar-web.stamp
dstar-web.stamp: dstar-template.stamp
	rm -rf dstar/corpora/$(dstar_corpus)
	svn co -N $(call svnroot,dstar)/corpus dstar/corpora/$(dstar_corpus)
	svn up dstar/corpora/$(dstar_corpus)/web
	svn up dstar/config/corpus/$(dstar_corpus).mak
	cd dstar/config/web && svn up $$(svn ls | grep -P '^\Q$(dstar_corpus).\E(?:rc|ttk)$$')
	touch $@

##-- dstar-web-clone: make -C dstar/corpora/$(dstar_corpus)/web init-clone
.PHONY: dstar-web-clone
dstar-web-clone: dstar-web-clone.stamp
dstar-web-clone.stamp: dstar-web.stamp
	make -C dstar/corpora/$(dstar_corpus)/web HOST=docker WEB_CLONE=$(dstar_web_clone) init-clone
	make -C dstar/corpora/$(dstar_corpus)/web HOST=docker clone-extra
	touch $@

##-- corpus-web: corpus web archive (snapshot, only generated once by make rules -- after that must be manually updated)
.PHONY: web web-force
web: web.tar.gz

ifeq ($(wildcard web.tar.gz),)
web.tar.gz: dstar-web-clone.stamp
	test \! -e $@ || rm -i $@
	tar c \
	 dstar/corpora/$(dstar_corpus) \
	 dstar/config/corpus/$(dstar_corpus).mak \
	 dstar/config/web \
	 | gzip --fast > $@
endif

force-web: web-force
web-force:
	test \! -e web.tar.gz || rm -f web.tar.gz
	$(MAKE) web.tar.gz

##-- dist-web : saves web.tar.gz snapshot
.PHONY: web-dist
web-dist: $(distdir)/$(distbase).web.tar.gz
$(distdir)/$(distbase).web.tar.gz: web.tar.gz
	test \! -e $@ || rm -i $@
	ln $< $@

web-dist-force:
	$(MAKE) no-web-dist && $(MAKE) web-dist

no-web-dist:
	-rm -f $(distdir)/$(distbase).web.tar.gz
