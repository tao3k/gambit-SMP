# makefile for Gambit system.

# Copyright (c) 1994-2023 by Marc Feeley, All Rights Reserved.

PACKAGE_SHORTNAME = gambit
PACKAGE_NAME = Gambit
PACKAGE_VERSION = v4.9.8
PACKAGE_STRING = Gambit v4.9.8
PACKAGE_BUGREPORT = gambit@iro.umontreal.ca
PACKAGE_TARNAME = gambit-v4_9_8



srcdir = .

srcdirpfx = 

CONFIGURE_COMMAND = ./configure '--enable-march=' '--enable-single-host=0' '--enable-multiple-vms' '--enable-smp' '--enable-c-opt=-O1' '--enable-c-opt-rts=yes' '--enable-gcc-opts' '--enable-inline-jumps' '--enable-dynamic-clib' '--enable-trust-c-tco' '--enable-multiple-threaded-vms' '--cache-file=/Users/guangtao/ghq/github.com/tao3k/gerbil-bazel/.data/gambit-SMP/.cache/tasks/modern-c-frame-contract/build/gambit-core/16a8e0b205a5a975c3ac653b3533112191011eba983fc7145f197a1e4920b880/configure-cache-8eb1559787d62779f11f44672f7ca6d010aa1cfd4361c5b87674b2a5afe8c714' 'CC=/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16' 'CFLAGS=-pipe -std=c23'

C_COMPILER = /opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16
C_PREPROC = /opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16 -E
FLAGS_OBJ = -pipe -std=c23    -Wno-unused -Wno-write-strings -Wdisabled-optimization -fwrapv -fno-strict-aliasing -fno-trapping-math -fno-math-errno -fschedule-insns2 -fmodulo-sched -freschedule-modulo-scheduled-loops -foptimize-sibling-calls -fomit-frame-pointer -fipa-ra -fmove-loop-invariants -fPIC -fno-common  
FLAGS_DYN =  -pipe -std=c23   -bundle  -Wno-unused -Wno-write-strings -Wdisabled-optimization -fwrapv -fno-strict-aliasing -fno-trapping-math -fno-math-errno -fschedule-insns2 -fmodulo-sched -freschedule-modulo-scheduled-loops -foptimize-sibling-calls -fomit-frame-pointer -fipa-ra -fmove-loop-invariants -fPIC -fno-common   
FLAGS_LIB =  -pipe -std=c23   -dynamiclib -install_name $(libdir)/$(LIBRARY)$(LIB_VERSION_SUFFIX)   
FLAGS_EXE =  -pipe -std=c23    -Wno-unused -Wno-write-strings -Wdisabled-optimization -fwrapv -fno-strict-aliasing -fno-trapping-math -fno-math-errno -fschedule-insns2 -fmodulo-sched -freschedule-modulo-scheduled-loops -foptimize-sibling-calls -fomit-frame-pointer -fipa-ra -fmove-loop-invariants -fPIC -fno-common     -Wno-unused -Wno-write-strings -Wdisabled-optimization -fwrapv -fno-strict-aliasing -fno-trapping-math -fno-math-errno -fschedule-insns2 -fmodulo-sched -freschedule-modulo-scheduled-loops -foptimize-sibling-calls -fomit-frame-pointer -fipa-ra -fmove-loop-invariants -fPIC -fno-common   
FLAGS_OPT =  -O1
FLAGS_OPT_RTS =  -O3
DEFS = -DHAVE_CONFIG_H
LIBS =  

GAMBITLIB_DEFS =  -D___GAMBITDIR="\"/usr/local/Gambit\"" -D___GAMBITDIR_USERLIB="\"\176/.gambit_userlib\"" -D___GAMBITDIR_INSTLIB="\"\176\176userlib\"" -D___SYS_TYPE_CPU="\"aarch64\"" -D___SYS_TYPE_VENDOR="\"apple\"" -D___SYS_TYPE_OS="\"darwin25.6.0\"" -D___CONFIGURE_COMMAND="\"./configure '--enable-march=' '--enable-single-host=0' '--enable-multiple-vms' '--enable-smp' '--enable-c-opt=-O1' '--enable-c-opt-rts=yes' '--enable-gcc-opts' '--enable-inline-jumps' '--enable-dynamic-clib' '--enable-trust-c-tco' '--enable-multiple-threaded-vms' '--cache-file=/Users/guangtao/ghq/github.com/tao3k/gerbil-bazel/.data/gambit-SMP/.cache/tasks/modern-c-frame-contract/build/gambit-core/16a8e0b205a5a975c3ac653b3533112191011eba983fc7145f197a1e4920b880/configure-cache-8eb1559787d62779f11f44672f7ca6d010aa1cfd4361c5b87674b2a5afe8c714' 'CC=/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16' 'CFLAGS=-pipe -std=c23'"\" -D___OBJ_EXTENSION="\".o\"" -D___EXE_EXTENSION="\"\"" -D___BAT_EXTENSION="\"\""
LIB_PREFIX = lib
LIB_VERSION_SUFFIX = 
LIB_MAJOR_VERSION_SUFFIX = 

LIB_EXTENSION = .a
GAMBITLIB = gambit
GAMBITGSCLIB = gambitgsc
GAMBITGSILIB = gambitgsi
INSTALL = $(rootfromhere)/install-sh -c
INSTALL_DATA = $(rootfromhere)/install-sh -c -m 644
INSTALL_LIB = $(rootfromhere)/install-sh -c -m 644
INSTALL_PROGRAM = $(rootfromhere)/install-sh -c -m 755
LN_S = ln -s
RANLIB = ranlib
AR = ar
RC = git
GIT = git
HG = hg

BOOTSTRAP_CONFIGURE_FLAGS =  --enable-c-opt=-O1

prefix = /usr/local/Gambit
exec_prefix = ${prefix}
includedir = ${prefix}/include
libdir = ${prefix}/lib
bindir = ${prefix}/bin
docdir = ${prefix}/doc
infodir = ${prefix}/info
emacsdir = ${datadir}/emacs/site-lisp
libexecdir = ${exec_prefix}/libexec
datarootdir = ${prefix}/share
datadir = ${prefix}/share
htmldir = ${docdir}
dvidir = ${docdir}
pdfdir = ${docdir}
psdir = ${docdir}
localedir = ${datarootdir}/locale
mandir = ${datarootdir}/man

# This directory's subdirectories are mostly independent; you can cd
# into them and run `make' without going through this makefile.
# To change the values of `make' variables: instead of editing makefiles,
# (1) if the variable is set in `config.status', edit `config.status'
#     (which will cause the makefiles to be regenerated when you run `make');
# (2) otherwise, pass the desired values on the `make' command line.

MDEFINES = prefix="$(prefix)" exec_prefix="$(exec_prefix)" \
includedir="$(includedir)" libdir="$(libdir)" \
bindir="$(bindir)" docdir="$(docdir)" \
infodir="$(infodir)" emacsdir="$(emacsdir)"

SUBDIRS = include bin lib gsi gsc misc doc tests examples contrib prebuilt bench githooks

RCFILES = README README.md INSTALL.txt LICENSE-2.0.txt LGPL.txt \
makefile.in configure configure.ac config.guess config.sub install-sh mkidirs \
relpath gsc-boot.unix gsc-boot.bat.windows appveyor.yml

GITRCFILES = .gitignore .gitattributes
HGRCFILES = .hgignore .hgtags

GENDISTFILES =

DISTFILES = $(RCFILES) $(GENDISTFILES)

GITDISTFILES = $(GITRCFILES)
HGDISTFILES = $(HGRCFILES)

#BUILD_FARM = farm
BUILD_FARM = localhost
#BUILD_HOST = baro.iro.umontreal.ca
BUILD_HOST = localhost

.SUFFIXES:

all: core
	$(MAKE) modules  # comment this line during development to avoid building the modules on every change

core:

core-pre: gsc-boot
	$(MAKE) stamp
	@if echo "MAKEFLAGS: $(MAKEFLAGS)" | fgrep -e "--jobserver-" > /dev/null; then \
	  $(MAKE) phases; \
	fi

core-post:
	@echo "*** to compile the builtin modules you should: make modules"

phases:
	@for phase in phase1 phase2 phase3 phase4; do \
	  echo "*** making $$phase"; \
	  $(MAKE) $$phase; \
	done

phase1: include-phase1 bin-phase1 lib-phase1 gsi-phase1 gsc-phase1

phase2: include-phase2 bin-phase2 lib-phase2 gsi-phase2 gsc-phase2

phase3: include-phase3 bin-phase3 lib-phase3 gsi-phase3 gsc-phase3

phase4: include-phase4 bin-phase4 lib-phase4 gsi-phase4 gsc-phase4

include-phase1 bin-phase1 lib-phase1 gsi-phase1 gsc-phase1 include-phase2 bin-phase2 lib-phase2 gsi-phase2 gsc-phase2 include-phase3 bin-phase3 lib-phase3 gsi-phase3 gsc-phase3 include-phase4 bin-phase4 lib-phase4 gsi-phase4 gsc-phase4:
	@target=`echo $@ | sed 's/.*-//'`; \
	subdir=`echo $@ | sed 's/-phase.*//'`; \
	echo making $$target in $$subdir; \
	(cd $$subdir && $(MAKE) $$target) || exit 1

from-scratch: fake_target
	$(MAKE) bootclean
	$(MAKE) bootstrap # make gsc compiler corresponding to repo HEAD
	$(MAKE) bootclean
	$(MAKE) core       # make everything with repo HEAD gsc compiler

boot-most-recent-release: fake_target
	@if test -x "boot/gsc-boot" && \
	    test "`boot/gsc-boot -v | sed -e 's/ .*//'`" = "$(PACKAGE_VERSION)"; then \
	  echo "*** boot/gsc-boot doesn't need to be rebuilt"; \
	else \
	  $(MAKE) boot-most-recent-release-gsc-boot; \
	fi

boot-most-recent-release-gsc-boot: fake_target
	@echo "*** building boot/gsc-boot"
	rm -rf boot
	mkdir -p boot
	$(GIT) archive tags/$(PACKAGE_VERSION) | (cd boot && tar xf -)
	cp config.guess boot
	cp config.sub boot
	cd boot && \
	./configure $(BOOTSTRAP_CONFIGURE_FLAGS) CC='$(C_COMPILER)' && \
	$(MAKE) bootstrap

boot-wip-compiler: fake_target
	@if test -x "boot/gsc/gsc" && \
	    test "`boot/gsc/gsc -v | sed -e 's/ .*//'`" = "$(PACKAGE_VERSION)" && \
	    test "`find gsc/makefile.in gsc/*.scm -exec diff -q \{\} boot/\{\} \; 2>&1`" = ""; then \
	  echo "*** boot/gsc/gsc doesn't need to be rebuilt"; \
	else \
	  $(MAKE) boot-wip-compiler-gsc-gsc && $(MAKE) bootclean; \
	fi

boot-wip-compiler-gsc-gsc: boot-most-recent-release
	@echo "*** building boot/gsc/gsc using boot/gsc-boot"
	cd boot && \
	rm -f gsc/makefile && \
	cp ../gsc/makefile.in ../gsc/*.scm gsc && \
	./configure $(BOOTSTRAP_CONFIGURE_FLAGS) CC='$(C_COMPILER)' && \
	for i in lib gsi gsc ; do (cd $$i ; $(MAKE) all) ; done

wip-gsc-boot: boot-wip-compiler
	cp boot/gsc/gsc gsc-boot

current-gsc-boot: wip-gsc-boot

dummy-gsc-boot:
	rm -f gsc-boot gsc-boot
	cp gsc-boot.bat.windows gsc-boot
	cp gsc-boot.unix gsc-boot
	chmod +x gsc-boot

gsc-boot:
	@if [ -e .git ] && \
	    $(GIT) --version > /dev/null 2> /dev/null && \
	    $(GIT) describe --tags > /dev/null 2> /dev/null && \
	    test "`$(GIT) describe --tags`" != "$(PACKAGE_VERSION)"; then \
	  echo "*** checking if current gsc-boot must be built"; \
	  $(MAKE) current-gsc-boot; \
	else \
	  echo "*** using a dummy gsc-boot"; \
	  $(MAKE) dummy-gsc-boot; \
	fi

fake_target:

doc info pdf html txt: fake_target
	@cd doc && $(MAKE) $(MDEFINES) $@

check ut-coverage ut ut-C ut-js ut-python ut-ruby ut-php ut-java st-coverage st st-C st-js st-python st-ruby st-php st-java: fake_target core
	@cd tests && $(MAKE) $(MDEFINES) $@

bench: fake_target core
	@cd bench && $(MAKE) $(MDEFINES) $@

examples: fake_target core
	@cd examples && $(MAKE) $(MDEFINES) $@

prebuilt: dist dist-devel
	PATH="gsi:$$PATH" prebuilt/remote-connect $(BUILD_FARM) "" "(define tmpdir \"gambtmp0\")(define gambit-dist \"$(PACKAGE_TARNAME)\")(define timeout 3000)(ssh timeout (string-append \"rm -rf \" tmpdir \";mkdir \" tmpdir \";echo \\\"logged in on:\\\";hostname\"))(scp-to timeout (string-append gambit-dist \".tgz\") (string-append tmpdir \"/.\"))(ssh timeout (string-append \"ssh $(BUILD_HOST) \\\"cd \" tmpdir \";tar zxf \" gambit-dist \".tgz;cd \" gambit-dist \";./configure CC=gcc-9;make -j;mv ../\" gambit-dist \".tgz .;cd prebuilt;make prebuilt\\\"\"))(scp-from timeout (string-append tmpdir \"/\" gambit-dist \"/$(PACKAGE_TARNAME)-*\") \".\")"
	@# cd prebuilt && $(MAKE) $(MDEFINES) $@

xactlog: fake_target
	@cd contrib/xactlog && $(MAKE) $(MDEFINES) $@

stamp: fake_target
	@cd include && $(MAKE) $(MDEFINES) $@

commit: deselect-gen-for-commit
	$(RC) commit

diff: fake_target
	@$(RC) diff | cat

log: fake_target
	@$(RC) log | cat

status: fake_target
	@$(RC) status || :

push: fake_target
	@if test "$(RC)" = "$(GIT)"; then \
	  $(GIT) push git@github.com:gambit/gambit.git; \
	  $(GIT) push --tags git@github.com:gambit/gambit.git; \
	else \
	  $(HG) push; \
	fi

pull: fake_target
	@if test "$(RC)" = "$(GIT)"; then \
	  $(GIT) pull; \
	  $(GIT) fetch --tags; \
	else \
	  $(HG) pull; \
	fi

update-nopull: fake_target
	@if test "$(RC)" = "$(GIT)"; then \
	  next_version=`$(GIT) tag | fgrep -e '-bootstrap' | sed -e 's/v//g' -e 's/-bootstrap.*//g' | sort -r -s -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n | sed 's/^/v/g' | sed -n '/^$(PACKAGE_VERSION)/{n;p;}'`; \
	else \
	  next_version=`$(HG) tags | fgrep -e '-bootstrap' | sed -e 's/v//g' -e 's/-bootstrap.*//g' | sort -r -s -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n | sed 's/^/v/g' | sed -n '/^$(PACKAGE_VERSION)/{n;p;}'`; \
	fi; \
	if test "$$next_version" = ""; then \
	  if test "$(RC)" = "$(GIT)"; then \
	    $(GIT) checkout master; \
	  else \
	    $(HG) checkout; \
	  fi; \
	else \
	  $(RC) checkout $$next_version-bootstrap; \
	  $(MAKE) bootstrap; \
	  $(RC) checkout $$next_version; \
	  $(MAKE) bootclean bootstrap update; \
	fi

update: pull update-nopull
	$(MAKE)

new-major: fake_target
	major=`echo $(PACKAGE_VERSION) | sed -e "s/v//g" -e "s/\.[^.]*\.[^.]*//g"`; \
	next_major=`eval expr 1 + $$major`; \
	next_version=v$$next_major.0.0; \
	$(MAKE) NEW_VERSION=$$next_version change-version

new-minor: fake_target
	major=`echo $(PACKAGE_VERSION) | sed -e "s/v//g" -e "s/\.[^.]*\.[^.]*//g"`; \
	minor=`echo $(PACKAGE_VERSION) | sed -e "s/v[^.]*\.//g" -e "s/\.[^.]*//g"`; \
	next_minor=`eval expr 1 + $$minor`; \
	next_version=v$$major.$$next_minor.0; \
	$(MAKE) NEW_VERSION=$$next_version change-version

new-revision: fake_target
	major=`echo $(PACKAGE_VERSION) | sed -e "s/v//g" -e "s/\.[^.]*\.[^.]*//g"`; \
	minor=`echo $(PACKAGE_VERSION) | sed -e "s/v[^.]*\.//g" -e "s/\.[^.]*//g"`; \
	revision=`echo $(PACKAGE_VERSION) | sed -e "s/v[^.]*\.[^.]*\.//g" -e "s///g"`; \
	next_revision=`eval expr 1 + $$revision`; \
	next_version=v$$major.$$minor.$$next_revision; \
	$(MAKE) NEW_VERSION=$$next_version change-version

change-version: deselect-gen-for-commit
	major=`echo $(PACKAGE_VERSION) | sed -e "s/v//g" -e "s/\.[^.]*\.[^.]*//g"`; \
	minor=`echo $(PACKAGE_VERSION) | sed -e "s/v[^.]*\.//g" -e "s/\.[^.]*//g"`; \
	revision=`echo $(PACKAGE_VERSION) | sed -e "s/v[^.]*\.[^.]*\.//g" -e "s///g"`; \
	next_major=`echo $(NEW_VERSION) | sed -e "s/v//g" -e "s/\.[^.]*\.[^.]*//g"`; \
	next_minor=`echo $(NEW_VERSION) | sed -e "s/v[^.]*\.//g" -e "s/\.[^.]*//g"`; \
	next_revision=`echo $(NEW_VERSION) | sed -e "s/v[^.]*\.[^.]*\.//g" -e "s///g"`; \
	version_num=`eval expr "\( 100000 \\* $$major \) + \( 1000 \\* $$minor \) + $$revision"`; \
	new_version_num=`eval expr "\( 100000 \\* $$next_major \) + \( 1000 \\* $$next_minor \) + $$next_revision"`; \
	sed -e "/(define (compiler-version) $$version_num)/s/$$version_num/$$new_version_num/" gsc/_parms.scm > gsc/_parms.scm-new; \
	if ! diff gsc/_parms.scm gsc/_parms.scm-new > /dev/null; then \
	  mv gsc/_parms.scm-new gsc/_parms.scm; \
	  if test "$(RC)" = "$(GIT)"; then \
	    $(GIT) commit -a -m "[COMPILER CHANGES NEEDED FOR $(NEW_VERSION)] Changed version in compiler"; \
	  else \
	    $(HG) commit -m "[COMPILER CHANGES NEEDED FOR $(NEW_VERSION)] Changed version in compiler"; \
	  fi; \
	  $(RC) tag $(NEW_VERSION)-bootstrap; \
	  if $(MAKE) bootstrap; then \
	    misc/changev $$version_num $$new_version_num; \
	    touch doc/gambit.txi; \
	    cd tests;  ../gsc/gsc -:~~bin=../bin,~~lib=../lib,~~include=../include -f -warnings -c -nb-gvm-regs 5 -nb-arg-regs 3 mix.scm; mv mix.c test5.ok; cd ..; \
	    (cd include; $(MAKE) RELEASE_VERSION=$(NEW_VERSION) stamp-release); \
	    if $(MAKE) bootclean && $(MAKE) -j && $(MAKE) check && $(MAKE) doc && $(MAKE) select-gen-for-commit; then \
	      if test "$(RC)" = "$(GIT)"; then \
	        $(GIT) commit -a -m "[RUNTIME CHANGES NEEDED FOR $(NEW_VERSION)] Changed version of runtime using misc/changev"; \
	      else \
	        $(HG) commit -m "[RUNTIME CHANGES NEEDED FOR $(NEW_VERSION)] Changed version of runtime using misc/changev"; \
	      fi; \
	      $(RC) tag $(NEW_VERSION); \
	    fi; \
	  fi; \
	else \
	  echo Compiler version in gsc/_parms.scm is inconsistent with PACKAGE_VERSION; \
	fi

release: fake_target
	$(MAKE) bootstrap
	$(MAKE) clean
	$(MAKE) all
	$(MAKE) check
	$(MAKE) doc
	rm -f $(PACKAGE_TARNAME).tgz $(PACKAGE_TARNAME)-*.*
	$(MAKE) prebuilt

publish-release: fake_target
	misc/publish-release $(PACKAGE_VERSION) $(PACKAGE_TARNAME).tgz $(PACKAGE_TARNAME)-*.*


print-make:
	echo $(MAKE)

clean-modules: clean-modules-pre
	@cd lib && $(MAKE) $@

clean-modules-pre:

list-modules: list-modules-pre
	@cd lib && $(MAKE) $@

list-modules-pre:

test-modules-all: test-modules-all-pre
	@cd lib && $(MAKE) $@

test-modules-all-pre:

test-modules: test-modules-pre
	@cd lib && $(MAKE) $@

test-modules-pre:

modules _gambit.java _gambit.js _gambit.php _gambit.py _gambit.rb _gambit.go:
	@cd lib && $(MAKE) $(MDEFINES) $@

update-unicode:
	@cd lib && $(MAKE) $(MDEFINES) $@

bootstrap-pre: core

bootstrap-post:

install-pre:
	@if test "no" = "yes" -a "no" = "yes" -a "$(DESTDIR)" != ""; then \
	  echo "*** The use of --enable-shared and --enable-absolute-shared-libs is"; \
	  echo "*** incompatible with the use of DESTDIR.  You can either specify an"; \
	  echo "*** empty DESTDIR or reconfigure with --disable-absolute-shared-libs."; \
	  exit 1; \
	fi

install-post: core
	if test "no" = "yes"; then \
	  if test "" = ""; then \
	    $(srcdirpfx)./mkidirs "$(DESTDIR)$(prefix)"; \
	    rm -f "$(DESTDIR)$(prefix)/../current" \
	      "$(DESTDIR)$(prefix)/../current.lnk"; \
	    (cd "$(DESTDIR)$(prefix)/.." && $(LN_S) $(PACKAGE_VERSION) current); \
	  fi; \
	fi

uninstall-pre:

uninstall-post:
	if test "no" = "yes"; then \
	  if test "" = ""; then \
	    (cd "$(DESTDIR)$(prefix)/.." && \
	     rm -f current && \
	     rmdir $(PACKAGE_VERSION)); \
	  fi; \
	fi

select-gen-for-commit-pre:

select-gen-for-commit-post select-gen-for-commit-post-nonrec:

deselect-gen-for-commit-pre:

deselect-gen-for-commit-post deselect-gen-for-commit-post-nonrec:

mostlyclean-pre:

mostlyclean-post mostlyclean-post-nonrec:

clean-pre: mostlyclean-pre

clean-post clean-post-nonrec: mostlyclean-post-nonrec

distclean-pre: clean-pre

distclean-post distclean-post-nonrec: clean-post-nonrec

bootclean-pre: distclean-pre

bootclean-post bootclean-post-nonrec: distclean-post-nonrec

realclean-pre: bootclean-pre

realclean-post realclean-post-nonrec: bootclean-post-nonrec
	rm -f config.log config.status makefile

rc-setup-pre:
	$(RC) init
	@if test "$(RC)" = "$(GIT)"; then \
	  $(GIT) add $(RCFILES) $(GITRCFILES); \
	  rm -f .git/config; \
	  echo '[core]' >> .git/config; \
	  echo '	repositoryformatversion = 0' >> .git/config; \
	  echo '	fileMode = false' >> .git/config; \
	  echo '	bare = false' >> .git/config; \
	  echo '	logallrefupdates = true' >> .git/config; \
	  echo '	ignorecase = true' >> .git/config; \
	  echo '	autocrlf = false' >> .git/config; \
	  echo '[remote "origin"]' >> .git/config; \
	  echo '	url = git@github.com:gambit/gambit.git' >> .git/config; \
	  echo '	fetch = +refs/heads/*:refs/remotes/origin/*' >> .git/config; \
	  echo '[branch "master"]' >> .git/config; \
	  echo '	remote = origin' >> .git/config; \
	  echo '	merge = refs/heads/master' >> .git/config; \
	else \
	  $(HG) add $(RCFILES) $(HGRCFILES); \
	  rm -f .hg/hgrc; \
	  echo "[paths]" > .hg/hgrc; \
	  echo "default-push = ssh://gambit@frontal07.iro.umontreal.ca/HTML/repo/gambit" >> .hg/hgrc; \
	  echo "default = http://www.iro.umontreal.ca/~gambit/repo/gambit/" >> .hg/hgrc; \
	fi

rc-setup-post:
	@if test "$(RC)" = "$(GIT)"; then \
	  $(GIT) commit -a -m "Initial commit of $(PACKAGE_STRING)"; \
	else \
	  $(HG) commit -m "Initial commit of $(PACKAGE_STRING)"; \
	fi

dist-pre: doc
	rm -rf $(PACKAGE_TARNAME)
	mkdir $(PACKAGE_TARNAME)
	chmod 777 $(PACKAGE_TARNAME)
	@echo "  Copying distribution files:"
	@for file in $(DISTFILES); do \
	  echo "    $$file"; \
	  ln $(srcdirpfx)$$file $(PACKAGE_TARNAME) 2> /dev/null \
	    || cp -p $(srcdirpfx)$$file $(PACKAGE_TARNAME); \
	done

dist-post:
	COPYFILE_DISABLE=1 tar chof $(PACKAGE_TARNAME).tar $(PACKAGE_TARNAME)
	gzip -9 $(PACKAGE_TARNAME).tar
	mv $(PACKAGE_TARNAME).tar.gz $(PACKAGE_TARNAME).tgz
	rm -rf $(PACKAGE_TARNAME)

dist-devel-pre: doc
	rm -rf $(PACKAGE_TARNAME)
	mkdir $(PACKAGE_TARNAME)
	chmod 777 $(PACKAGE_TARNAME)
	@echo "  Copying distribution files:"
	@for file in $(DISTFILES); do \
	  echo "    $$file"; \
	  ln $(srcdirpfx)$$file $(PACKAGE_TARNAME) 2> /dev/null \
	    || cp -p $(srcdirpfx)$$file $(PACKAGE_TARNAME); \
	done
	@if test "$(RC)" = "$(GIT)"; then \
	  for file in $(GITDISTFILES); do \
	    echo "    $$file"; \
	    ln $(srcdirpfx)$$file $(PACKAGE_TARNAME) 2> /dev/null \
	      || cp -p $(srcdirpfx)$$file $(PACKAGE_TARNAME); \
	  done; \
	  echo "    .git"; \
	  ln $(srcdirpfx).git $(PACKAGE_TARNAME) 2> /dev/null \
	    || cp -p -R $(srcdirpfx).git $(PACKAGE_TARNAME); \
	  echo "    .github"; \
	  ln $(srcdirpfx).github $(PACKAGE_TARNAME) 2> /dev/null \
	    || cp -p -R $(srcdirpfx).github $(PACKAGE_TARNAME); \
	else \
	  for file in $(HGDISTFILES); do \
	    echo "    $$file"; \
	    ln $(srcdirpfx)$$file $(PACKAGE_TARNAME) 2> /dev/null \
	      || cp -p $(srcdirpfx)$$file $(PACKAGE_TARNAME); \
	  done; \
	  echo "    .hg"; \
	  ln $(srcdirpfx).hg $(PACKAGE_TARNAME) 2> /dev/null \
	    || cp -p -R $(srcdirpfx).hg $(PACKAGE_TARNAME); \
	  echo "    .github"; \
	  ln $(srcdirpfx).github $(PACKAGE_TARNAME) 2> /dev/null \
	    || cp -p -R $(srcdirpfx).github $(PACKAGE_TARNAME); \
	fi

dist-devel-post:
	rm -rf $(PACKAGE_TARNAME)-devel
	mv $(PACKAGE_TARNAME) $(PACKAGE_TARNAME)-devel
	COPYFILE_DISABLE=1 tar chof $(PACKAGE_TARNAME)-devel.tar $(PACKAGE_TARNAME)-devel
	gzip -9 $(PACKAGE_TARNAME)-devel.tar
	mv $(PACKAGE_TARNAME)-devel.tar.gz $(PACKAGE_TARNAME)-devel.tgz
	rm -rf $(PACKAGE_TARNAME)-devel

dist-boot-post:
	rm -rf boot-$(PACKAGE_TARNAME)
	mkdir boot-$(PACKAGE_TARNAME)
	chmod 777 boot-$(PACKAGE_TARNAME)
	mv $(PACKAGE_TARNAME) boot-$(PACKAGE_TARNAME)/boot
	(cd boot-$(PACKAGE_TARNAME) && COPYFILE_DISABLE=1 tar chof boot.tar boot && gzip -9 boot.tar) || exit 1
	mv boot-$(PACKAGE_TARNAME)/boot.tar.gz boot.tgz
	rm -rf boot-$(PACKAGE_TARNAME)

core-recursive bootstrap-recursive install-recursive uninstall-recursive select-gen-for-commit-recursive deselect-gen-for-commit-recursive mostlyclean-recursive clean-recursive distclean-recursive bootclean-recursive realclean-recursive rc-setup-recursive dist-recursive dist-devel-recursive:
	@for subdir in $(SUBDIRS); do \
	  target=`echo $@ | sed 's/-recursive//'`; \
	  echo making $$target in $$subdir; \
	  (cd $$subdir && $(MAKE) $$target) || exit 1; \
	done

core: core-post

core-post: core-recursive

core-recursive: core-pre

bootstrap: bootstrap-post

bootstrap-post: bootstrap-recursive

bootstrap-recursive: bootstrap-pre

install: install-post

install-post: install-recursive

install-recursive: install-pre core

uninstall: uninstall-post

uninstall-post: uninstall-recursive

uninstall-recursive: uninstall-pre

select-gen-for-commit: select-gen-for-commit-post

select-gen-for-commit-post: select-gen-for-commit-recursive

select-gen-for-commit-post-nonrec select-gen-for-commit-recursive: select-gen-for-commit-pre

deselect-gen-for-commit: deselect-gen-for-commit-post

deselect-gen-for-commit-post: deselect-gen-for-commit-recursive

deselect-gen-for-commit-post-nonrec deselect-gen-for-commit-recursive: deselect-gen-for-commit-pre

mostlyclean: mostlyclean-post

mostlyclean-post: mostlyclean-recursive

mostlyclean-post-nonrec mostlyclean-recursive: mostlyclean-pre

clean: clean-post

clean-post: clean-recursive

clean-post-nonrec clean-recursive: clean-pre

distclean: distclean-post

distclean-post: distclean-recursive

distclean-post-nonrec distclean-recursive: distclean-pre

bootclean: bootclean-post

bootclean-post: bootclean-recursive

bootclean-post-nonrec bootclean-recursive: bootclean-pre

realclean: realclean-post

realclean-post: realclean-recursive

realclean-post-nonrec realclean-recursive: realclean-pre

rc-setup: rc-setup-post

rc-setup-post: rc-setup-recursive

rc-setup-recursive: rc-setup-pre

dist: dist-post

dist-post: dist-recursive

dist-recursive: dist-pre

dist-devel: dist-devel-post

dist-devel-post: dist-devel-recursive

dist-devel-recursive: dist-devel-pre

dist-boot: dist-boot-post

dist-boot-post: dist-recursive

# For an explanation of the following makefile rules, see node
# `Automatic Remaking' in GNU Autoconf documentation.

makefile: makefile.in config.status
	CONFIG_FILES=$@ CONFIG_HEADERS= ./config.status

config.status: configure
	./config.status --recheck

configure: configure.ac
	cd $(srcdir) && WANT_AUTOCONF=2.69 autoconf configure.ac > configure && chmod 755 configure
	@if ! fgrep "# Generated by GNU Autoconf 2.69 " configure > /dev/null ; then \
	  echo "*********************************************************************"; \
	  echo "***"; \
	  echo "*** The file \"configure\" has been generated by Autoconf from"; \
	  echo "*** the file \"configure.ac\" using a version of Autoconf other"; \
	  echo "*** than 2.69. The file \"configure\" states:"; \
	  echo "*** `grep "^# Generated by GNU Autoconf " configure`"; \
	  echo "***"; \
	  echo "*** Versions of Autoconf other than 2.69 have caused issues in"; \
	  echo "*** the past, notably the \"configure\" script does not"; \
	  echo "*** determine the correct C compiler flags to access the"; \
	  echo "*** C math library functions."; \
	  echo "***"; \
	  echo "*** If you encounter issues with the build process then using"; \
	  echo "*** Autoconf 2.69 may be a solution."; \
	  echo "***"; \
	  echo "*********************************************************************"; \
	  sleep 5; \
	fi

# Tell versions [3.59,3.63) of GNU make not to export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
