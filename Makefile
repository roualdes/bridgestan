## include paths
BS_ROOT ?= .
SRC ?= $(BS_ROOT)/src/
STAN ?= $(BS_ROOT)/stan/
STANC ?= $(BS_ROOT)/bin/stanc$(EXE)
MATH ?= $(STAN)lib/stan_math/
RAPIDJSON ?= $(STAN)lib/rapidjson_1.1.0/

## required C++ includes
INC_FIRST ?= -I $(STAN)src -I $(RAPIDJSON)

## makefiles needed for math library
-include $(BS_ROOT)/make/local
-include $(MATH)make/compiler_flags
-include $(MATH)make/libraries

## Set -fPIC globally since we're always building a shared library
CXXFLAGS += -fPIC

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
ifdef BRIDGESTAN_AD_HESSIAN
	CXXFLAGS+=-DSTAN_MODEL_FVAR_VAR -DBRIDGESTAN_AD_HESSIAN
	STAN_FLAG_HESS=_adhessian
else
	STAN_FLAG_HESS=
endif
STAN_FLAGS=$(STAN_FLAG_THREADS)$(STAN_FLAG_OPENCL)$(STAN_FLAG_HESS)

BRIDGE_DEPS = $(SRC)bridgestan.cpp $(SRC)bridgestan.h $(SRC)model_rng.cpp $(SRC)model_rng.hpp $(SRC)bridgestanR.cpp $(SRC)bridgestanR.h $(SRC)callback_stream.hpp
BRIDGE_O = $(patsubst %.cpp,%$(STAN_FLAGS).o,$(SRC)bridgestan.cpp)

$(BRIDGE_O) : $(BRIDGE_DEPS)
	@echo ''
	@echo '--- Compiling Stan bridge C++ code ---'
	@mkdir -p $(dir $@)
	$(COMPILE.cpp) $(OUTPUT_OPTION) $(LDLIBS) $<

## generate .hpp file from .stan file using stanc
%.hpp : %.stan $(STANC)
	@echo ''
	@echo '--- Translating Stan model to C++ code ---'
	$(STANC) $(STANCFLAGS) --o=$(subst  \,/,$@) $(subst  \,/,$<)

## declares we want to keep .hpp even though it's an intermediate
.PRECIOUS: %.hpp

## builds executable (suffix depends on platform)
%_model.so : %.hpp $(BRIDGE_O) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo ''
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)
	@echo '--- Linking C++ code ---'
	$(LINK.cpp) -shared -lm -o $(patsubst %.hpp, %_model.so, $(subst \,/,$<)) $(subst \,/,$*.o) $(BRIDGE_O) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	$(RM) $(subst  \,/,$*).o

.PHONY: docs
docs:
	$(MAKE) -C docs/ html

.PHONY: clean
clean:
	$(RM) $(SRC)/*.o
	$(RM) test_models/**/*.so
	$(RM) test_models/**/*.hpp
	$(RM) bin/stanc$(EXE)


# build all test models at once
TEST_MODEL_NAMES = $(patsubst $(BS_ROOT)/test_models/%/, %, $(sort $(dir $(wildcard $(BS_ROOT)/test_models/*/))))
TEST_MODEL_NAMES := $(filter-out syntax_error, $(TEST_MODEL_NAMES))
TEST_MODEL_LIBS = $(join $(addprefix test_models/, $(TEST_MODEL_NAMES)), $(addsuffix _model.so, $(addprefix /, $(TEST_MODEL_NAMES))))

.PHONY: test_models
test_models: $(TEST_MODEL_LIBS)

.PHONY: stan-update stan-update-version
stan-update:
	git submodule update --init --recursive

stan-update-remote:
	git submodule update --remote --init --recursive

# print compilation command line config
.PHONY: compile_info
compile_info:
	@echo '$(LINK.cpp) $(BRIDGE_O) $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)'

## print value of makefile variable (e.g., make print-TBB_TARGETS)
.PHONY: print-%
print-%  : ; @echo $* = $($*) ;

# handles downloading of stanc
STANC_DL_RETRY = 5
STANC_DL_DELAY = 10
STANC3_TEST_BIN_URL ?=
STANC3_VERSION ?= v2.31.0

ifeq ($(OS),Windows_NT)
 OS_TAG := windows
else ifeq ($(OS),Darwin)
 OS_TAG := mac
else ifeq ($(OS),Linux)
 OS_TAG := linux
 ifeq ($(shell uname -m),mips64)
  ARCH_TAG := -mips64el
 else ifeq ($(shell uname -m),ppc64le)
  ARCH_TAG := -ppc64el
 else ifeq ($(shell uname -m),s390x)
  ARCH_TAG := -s390x
 else ifeq ($(shell uname -m),aarch64)
  ARCH_TAG := -arm64
 else ifeq ($(shell uname -m),armv7l)
  ifeq ($(shell readelf -A /usr/bin/file | grep Tag_ABI_VFP_args),)
    ARCH_TAG := -armel
  else
    ARCH_TAG := -armhf
  endif
 endif
endif

ifeq ($(OS_TAG),windows)
$(STANC):
	@mkdir -p $(dir $@)
	$(shell echo "curl -L https://github.com/stan-dev/stanc3/releases/download/$(STANC3_VERSION)/$(OS_TAG)-stanc -o $(STANC) --retry $(STANC_DL_RETRY) --retry-delay $(STANC_DL_DELAY)")
else
$(STANC):
	@mkdir -p $(dir $@)
	curl -L https://github.com/stan-dev/stanc3/releases/download/$(STANC3_VERSION)/$(OS_TAG)$(ARCH_TAG)-stanc -o $(STANC) --retry $(STANC_DL_RETRY) --retry-delay $(STANC_DL_DELAY)
	chmod +x $(STANC)
endif
