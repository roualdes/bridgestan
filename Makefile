## this Makefile assumes directory contents, structure:
##   ./bin - contains stanc compiler
##   ./lib - contains rapidjson parser library
##   ./src - contains cmdstan/io/json
##   <user-specified-path>stan - stan repo, contains model-header
##   <specified/path/to/stan>/stan/lib/stan_math - stan math library

## Other flags implicated in this build that we don't set
# STAN_OPENCL:  enable GPU routines

## include paths
GITHUB ?= $(HOME)/github/
CMDSTAN ?= $(GITHUB)stan-dev/cmdstan/
CMDSTANSRC ?= $(CMDSTAN)src/
STANC ?= $(CMDSTAN)bin/stanc
STAN ?= $(CMDSTAN)stan/
MATH ?= $(STAN)lib/stan_math/
# TBB_TARGETS = $(MATH)lib/tbb/libtbb.dylib
RAPIDJSON ?= $(CMDSTAN)lib/rapidjson_1.1.0/

## required C++ includes
INC_FIRST ?= -I $(STAN)src -I $(RAPIDJSON)

## set CXX = g++ and CX_TYPE to gcc to run under linux
OS ?= $(shell uname -s)
CXX ?= clang++
CXX_TYPE ?= clang

## makefiles needed for math library
-include $(MATH)make/compiler_flags
-include $(MATH)make/dependencies
-include $(MATH)make/libraries

## set flags for stanc compiler (math calls MIGHT? set STAN_OPENCL)
ifdef STAN_OPENCL
STANCFLAGS+= --use-opencl
endif

MAIN ?= src/main.cpp
MAIN_SO = $(patsubst %.cpp,%.so,$(MAIN))

## COMPILE (e.g., COMPILE.cpp == clang++ ...) was set by (MATH)make/compiler_flags
## UNKNOWNS:  OUTPUT_OPTION???  LDLIBS???
$(MAIN_SO) : $(MAIN)
	@echo ''
	@echo '--- Compiling Stan bridge C++ code ---'
	@mkdir -p $(dir $@)
	$(COMPILE.cpp) -DSTAN_THREADS -fPIC -O3 -march=native -I $(CMDSTANSRC) $(OUTPUT_OPTION) $(LDLIBS) $<

## generate .hpp file from .stan file using stanc
%.hpp : %.stan $(STANC)
	@echo ''
	@echo '--- Translating Stan model to C++ code ---'
	$(STANC) $(STANCFLAGS) --o=$(subst  \,/,$@) $(subst  \,/,$<)

## generate list of source file dependencies for generated .hpp file
%.d: %.hpp

## declares we want to keep .hpp even though it's an intermediate
.PRECIOUS: %.hpp

## builds executable (suffix depends on platform)
%$(EXE) : %.hpp $(MAIN_SO) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo ''
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) $(CXXFLAGS_PROGRAM) -DSTAN_THREADS -O3 -march=native -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)
	@echo '--- Linking C++ code ---'
	$(LINK.cpp) -shared -lm -fPIC -O3 -o $(patsubst %.hpp,%_model.so,$<) $(subst \,/,$*.o) $(MAIN_SO) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	$(RM) $(subst  \,/,$*).o

## calculate dependencies for %$(EXE) target
ifneq (,$(STAN_TARGETS))
$(patsubst %,%.d,$(STAN_TARGETS)) : DEPTARGETS += -MT $(patsubst %.d,%$(EXE),$@) -include $< -include $(MAIN)
-include $(patsubst %,%.d,$(STAN_TARGETS))
-include $(patsubst %.cpp,%.d,$(MAIN))
endif

## compiles and instantiates TBB library (only if not done automatically on platform)
.PHONY: install-tbb
install-tbb: $(TBB_TARGETS)

## clean targets (complex because they don't depend on unix find);
## findfiles defined ??? (MATH makefiles???)
.PHONY: clean clean-deps clean-all clean-program
clean-deps:
	@echo '  removing dependency files'
	$(RM) $(call findfiles,src,*.d) $(call findfiles,src/stan,*.d) $(call findfiles,$(MATH)/stan,*.d) $(call findfiles,$(STAN)/src/stan/,*.d)
	$(RM) $(call findfiles,src,*.d.*) $(call findfiles,src/stan,*.d.*) $(call findfiles,$(MATH)/stan,*.d.*)
	$(RM) $(call findfiles,src,*.dSYM) $(call findfiles,src/stan,*.dSYM) $(call findfiles,$(MATH)/stan,*.dSYM)

clean-all: clean clean-deps
	$(RM) $(MAIN_SO)
	$(RM) -r $(wildcard $(BOOST)/stage/lib $(BOOST)/bin.v2 $(BOOST)/tools/build/src/engine/bootstrap/ $(BOOST)/tools/build/src/engine/bin.* $(BOOST)/project-config.jam* $(BOOST)/b2 $(BOOST)/bjam $(BOOST)/bootstrap.log)

clean-program:
ifndef STANPROG
	$(error STANPROG not set)
endif
	$(RM) "$(wildcard $(patsubst %.stan,%.d,$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%.hpp,$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%.o,$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%$(EXE),$(basename ${STANPROG}).stan))"

# print compilation command line config
.PHONY: compile_info
compile_info:
	@echo '$(LINK.cpp) $(CXXFLAGS_PROGRAM) $(MAIN_SO) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)'

## print value of makefile variable (e.g., make print-TBB_TARGETS)
.PHONY: print-%
print-%  : ; @echo $* = $($*) ;
