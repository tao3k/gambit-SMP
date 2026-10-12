ifndef GAMBIT_SOURCE
$(error GAMBIT_SOURCE must name the identified runtime)
endif
ifndef WORK
$(error WORK must name a fresh output directory)
endif
FIXTURES := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
GSC := $(GAMBIT_SOURCE)/gsc/gsc
DRIVER := $(GAMBIT_SOURCE)/bin/gambuild-C
EXTRA_CC_OPTIONS ?=
HARNESS ?= sfun_families.c
VM_DIRS := -:p1,~~bin=$(GAMBIT_SOURCE)/bin,~~lib=$(GAMBIT_SOURCE)/lib,~~include=$(GAMBIT_SOURCE)/include
DRIVER_ENV = env GAMBITDIR_INCLUDE="$(GAMBIT_SOURCE)/include" GAMBITDIR_LIB="$(GAMBIT_SOURCE)/lib" GAMBITDIR_BIN="$(GAMBIT_SOURCE)/bin"
.PHONY: all
all: $(WORK)/sfun-families
$(WORK)/sfunfamilies.c: $(FIXTURES)/sfunfamilies.scm $(FIXTURES)/nestedmarker.scm $(FIXTURES)/nestedunwind.scm
	$(GSC) $(VM_DIRS) -c -o $@ $<
$(WORK)/sfunfamilies_.c: $(WORK)/sfunfamilies.c
	$(GSC) $(VM_DIRS) -link -o $@ $<
$(WORK)/%.o: $(WORK)/%.c
	$(DRIVER_ENV) BUILD_OBJ_OUTPUT_FILENAME_PARAM="$@" BUILD_OBJ_INPUT_FILENAMES_PARAM="$<" BUILD_OBJ_CC_OPTIONS_PARAM="-D___LIBRARY $(EXTRA_CC_OPTIONS)" $(DRIVER) obj
$(WORK)/sfun_families.o: $(FIXTURES)/$(HARNESS)
	$(DRIVER_ENV) BUILD_OBJ_OUTPUT_FILENAME_PARAM="$@" BUILD_OBJ_INPUT_FILENAMES_PARAM="$<" BUILD_OBJ_CC_OPTIONS_PARAM="-D___LIBRARY $(EXTRA_CC_OPTIONS)" $(DRIVER) obj
$(WORK)/sfun-families: $(WORK)/sfunfamilies.o $(WORK)/sfunfamilies_.o $(WORK)/sfun_families.o
	$(DRIVER_ENV) BUILD_EXE_OUTPUT_FILENAME_PARAM="$@" BUILD_EXE_INPUT_FILENAMES_PARAM="$^" $(DRIVER) exe
