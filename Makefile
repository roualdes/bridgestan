## include paths
GITHUB ?= $(HOME)/github/
CMDSTAN ?= $(GITHUB)stan-dev/cmdstan/
STANC ?= $(CMDSTAN)bin/stanc$(EXE)
STAN ?= $(CMDSTAN)stan/
MATH ?= $(STAN)lib/stan_math/
RAPIDJSON ?= $(STAN)lib/rapidjson_1.1.0/

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

SRC ?= src/
BRIDGE_DEPS = $(SRC)bridgestan.cpp $(SRC)bridgestan.h $(SRC)model_rng.cpp $(SRC)model_rng.hpp $(SRC)bridgestanR.cpp $(SRC)bridgestanR.h
BRIDGE_O = $(patsubst %.cpp,%$(STAN_FLAGS).o,$(SRC)bridgestan.cpp)

$(STANC):
	@echo 'stanc could not be found. Make sure CmdStan is installed and built, and that the path specificied is correct:'
	@echo '$(CMDSTAN)'
	exit 1

$(BRIDGE_O) : $(BRIDGE_DEPS)
	@echo ''
	@echo '--- Compiling Stan bridge C++ code ---'
	@mkdir -p $(dir $@)
	$(COMPILE.cpp) -fPIC $(CXXFLAGS_THREADS) $(OUTPUT_OPTION) $(LDLIBS) $<

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
%_model.so : %.hpp $(BRIDGE_O) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo ''
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) $(CXXFLAGS_PROGRAM) -fPIC $(CXXFLAGS_THREADS) -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)
	@echo '--- Linking C++ code ---'
	$(LINK.cpp) -shared -lm -fPIC -o $(patsubst %.hpp, %_model.so, $(subst \,/,$<)) $(subst \,/,$*.o) $(BRIDGE_O) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	$(RM) $(subst  \,/,$*).o

.PHONY: docs
docs:
	$(MAKE) -C docs/ html

.PHONY: clean
clean:
	$(RM) $(SRC)/*.o
	$(RM) test_models/**/*.so
	$(RM) test_models/**/*.hpp

# build all test models at once
TEST_MODEL_LIBS = test_models/throw_tp/throw_tp_model.so test_models/throw_gq/throw_gq_model.so test_models/throw_lp/throw_lp_model.so test_models/throw_data/throw_data_model.so test_models/jacobian/jacobian_model.so test_models/matrix/matrix_model.so test_models/simplex/simplex_model.so test_models/full/full_model.so test_models/stdnormal/stdnormal_model.so test_models/bernoulli/bernoulli_model.so test_models/gaussian/gaussian_model.so test_models/fr_gaussian/fr_gaussian_model.so test_models/simple/simple_model.so test_models/multi/multi_model.so

.PHONY: test_models
test_models: $(TEST_MODEL_LIBS)

# print compilation command line config
.PHONY: compile_info
compile_info:
	@echo '$(LINK.cpp) $(CXXFLAGS_PROGRAM) $(BRIDGE_O) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)'

## print value of makefile variable (e.g., make print-TBB_TARGETS)
.PHONY: print-%
print-%  : ; @echo $* = $($*) ;
