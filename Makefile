## include paths
GITHUB ?= $(HOME)/github/
CMDSTAN ?= $(GITHUB)stan-dev/cmdstan/
CMDSTANSRC ?= $(CMDSTAN)src/
STANC ?= $(CMDSTAN)bin/stanc$(EXE)
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
-include $(CMDSTAN)/make/local
-include $(MATH)make/compiler_flags
-include $(MATH)make/dependencies
-include $(MATH)make/libraries

## set flags for stanc compiler (math calls MIGHT? set STAN_OPENCL)
ifdef STAN_OPENCL
	STANCFLAGS += --use-opencl
	STAN_FLAG_OPENCL=_opencl
else
	STAN_FLAG_OPENCL=
endif
ifdef STAN_THREADS
	STAN_FLAG_THREADS=_threads
else
	STAN_FLAG_THREADS=
endif
STAN_FLAGS=$(STAN_FLAG_THREADS)$(STAN_FLAG_OPENCL)

BRIDGE ?= src/bridgestan.cpp
BRIDGE_SO = $(patsubst %.cpp,%$(STAN_FLAGS).so,$(BRIDGE))

## COMPILE (e.g., COMPILE.cpp == clang++ ...) was set by (MATH)make/compiler_flags
## UNKNOWNS:  OUTPUT_OPTION???  LDLIBS???
$(BRIDGE_SO) : $(BRIDGE)
	@echo ''
	@echo '--- Compiling Stan bridge C++ code ---'
	@mkdir -p $(dir $@)
	$(COMPILE.cpp) -fPIC $(CXXFLAGS_THREADS) -I $(CMDSTANSRC) $(OUTPUT_OPTION) $(LDLIBS) $<

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
%_model.so : %.hpp $(BRIDGE_SO) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo ''
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) $(CXXFLAGS_PROGRAM) -fPIC $(CXXFLAGS_THREADS) -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)
	@echo '--- Linking C++ code ---'
	$(LINK.cpp) -shared -lm -fPIC -o $(patsubst %.hpp, %_model.so, $(subst \,/,$<)) $(subst \,/,$*.o) $(BRIDGE_SO) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	$(RM) $(subst  \,/,$*).o

## calculate dependencies for %$(EXE) target
ifneq (,$(STAN_TARGETS))
$(patsubst %,%.d,$(STAN_TARGETS)) : DEPTARGETS += -MT $(patsubst %.d,%$(EXE),$@) -include $< -include $(BRIDGE)
-include $(patsubst %,%.d,$(STAN_TARGETS))
-include $(patsubst %.cpp,%.d,$(BRIDGE))
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
	$(RM) $(BRIDGE_SO)
	$(RM) -r $(wildcard $(BOOST)/stage/lib $(BOOST)/bin.v2 $(BOOST)/tools/build/src/engine/bootstrap/ $(BOOST)/tools/build/src/engine/bin.* $(BOOST)/project-config.jam* $(BOOST)/b2 $(BOOST)/bjam $(BOOST)/bootstrap.log)

clean-program:
ifndef STANPROG
	$(error STANPROG not set)
endif
	$(RM) "$(wildcard $(patsubst %.stan,%.d,$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%.hpp,$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%.o,$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%$(EXE),$(basename ${STANPROG}).stan))"
	$(RM) "$(wildcard $(patsubst %.stan,%_model.so,$(basename ${STANPROG}).stan))"

# print compilation command line config
.PHONY: compile_info
compile_info:
	@echo '$(LINK.cpp) $(CXXFLAGS_PROGRAM) $(BRIDGE_SO) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)'

## print value of makefile variable (e.g., make print-TBB_TARGETS)
.PHONY: print-%
print-%  : ; @echo $* = $($*) ;
