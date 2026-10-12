# Fixture assembly through the selected runtime's existing GNU build driver.
ifndef GAMBIT_SOURCE
$(error GAMBIT_SOURCE must name the identified freshly built runtime)
endif
ifndef WORK
$(error WORK must name a fresh fixture output directory)
endif
FIXTURES := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
GSC := $(GAMBIT_SOURCE)/gsc/gsc
DRIVER := $(GAMBIT_SOURCE)/bin/gambuild-C
VM_DIRS := -:p1,~~bin=$(GAMBIT_SOURCE)/bin,~~lib=$(GAMBIT_SOURCE)/lib,~~include=$(GAMBIT_SOURCE)/include
DRIVER_ENV = env GAMBITDIR_INCLUDE="$(GAMBIT_SOURCE)/include" GAMBITDIR_LIB="$(GAMBIT_SOURCE)/lib" GAMBITDIR_BIN="$(GAMBIT_SOURCE)/bin"

.PHONY: all
all: $(WORK)/checked-cleanup-embedding

$(WORK)/cleanupembed.c: $(FIXTURES)/cleanupembed.scm
	$(GSC) $(VM_DIRS) -c -o $@ $<

$(WORK)/cleanupembed_.c: $(WORK)/cleanupembed.c
	$(GSC) $(VM_DIRS) -link -o $@ $<

$(WORK)/%.o: $(WORK)/%.c
	$(DRIVER_ENV) BUILD_OBJ_OUTPUT_FILENAME_PARAM="$@" BUILD_OBJ_INPUT_FILENAMES_PARAM="$<" BUILD_OBJ_CC_OPTIONS_PARAM="-D___LIBRARY" $(DRIVER) obj

$(WORK)/checked_cleanup_embedding.o: $(FIXTURES)/checked_cleanup_embedding.c
	$(DRIVER_ENV) BUILD_OBJ_OUTPUT_FILENAME_PARAM="$@" BUILD_OBJ_INPUT_FILENAMES_PARAM="$<" BUILD_OBJ_CC_OPTIONS_PARAM="-D___LIBRARY" $(DRIVER) obj

$(WORK)/checked-cleanup-embedding: $(WORK)/cleanupembed.o $(WORK)/cleanupembed_.o $(WORK)/checked_cleanup_embedding.o
	$(DRIVER_ENV) BUILD_EXE_OUTPUT_FILENAME_PARAM="$@" BUILD_EXE_INPUT_FILENAMES_PARAM="$^" $(DRIVER) exe
