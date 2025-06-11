##-*- Mode: GNUmakefile; coding: utf-8; -*-

##==============================================================
## Rules: local hacks for 2020-10-05 snapshot

volume-sync:: volume-sync-2020-hacks

##-- 2020 hacks: top-level
volume-sync-2020-hacks:
	$(docker) run --rm $(volume_mount) dstar-base test ! -e $(volume_path)/mnt/SSD/ddc-dstar/dstar/config \
	  || $(MAKE) volume-sync-2020-hack-mnt-ssd
	$(docker) run --rm $(volume_mount) dstar-base test ! -e $(volume_path)/config/dta_common.mak \
	  || $(MAKE) volume-sync-2020-hack-dta-common

##-- 2020 hacks: fix bogus /mnt/SSD/ddc-dstar/dstar/config/
volume-sync-2020-hack-mnt-ssd:
	$(docker) run --rm $(volume_mount) dstar-base mv -T $(volume_path)/mnt/SSD/ddc-dstar/dstar/config $(volume_path)/config
	$(docker) run --rm $(volume_mount) dstar-base find $(volume_path)/mnt \! -type d | grep -q . \
	  || $(docker) run --rm $(volume_mount) dstar-base rm -rf $(volume_path)/mnt

##-- 2020 hacks: fix missing config/corpus/dta_common.mak , config/web/dta_.{rc,ttk}
volume-sync-2020-hack-dta-common:
	cat ../../data/dta-extra-2020-10-05.tar.gz \
	 | $(docker) run -i --rm $(volume_mount) dstar-base tar xvz -C $(volume_path)
