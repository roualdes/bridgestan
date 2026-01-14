# include paths
BS_ROOT ?= .

# user config
-include $(BS_ROOT)/make/local

SRC ?= $(BS_ROOT)/src/
STAN ?= $(BS_ROOT)/stan/
STANC ?= $(BS_ROOT)/bin/stanc$(EXE)
MATH ?= $(STAN)lib/stan_math/
RAPIDJSON ?= $(STAN)lib/rapidjson_1.1.0/

# required C++ includes
INC_FIRST ?= -I $(STAN)src -I $(RAPIDJSON)

# makefiles needed for math library
include $(MATH)make/compiler_flags
include $(MATH)make/libraries

# Set -fPIC globally since we're always building a shared library
override CXXFLAGS += -fPIC
override CXXFLAGS_SUNDIALS += -fPIC

# visibility control
override CXXFLAGS += -fvisibility=hidden -fvisibility-inlines-hidden
override CPPFLAGS += -DBRIDGESTAN_EXPORT -DSTAN_OVERRIDE_EIGEN_ASSERT

ifdef STAN_OPENCL
	override STANCFLAGS += --use-opencl
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
	override CPPFLAGS += -DSTAN_MODEL_FVAR_VAR -DBRIDGESTAN_AD_HESSIAN
	STAN_FLAG_HESS=_adhessian
else
	STAN_FLAG_HESS=
endif
STAN_FLAGS=$(STAN_FLAG_THREADS)$(STAN_FLAG_OPENCL)$(STAN_FLAG_HESS)

BRIDGE_DEPS = $(SRC)bridgestan.cpp $(SRC)bridgestan.h $(SRC)bridgestanR.cpp $(SRC)bridgestanR.h $(wildcard $(SRC)*.hpp)
BRIDGE_O = $(patsubst %.cpp,%$(STAN_FLAGS).o,$(SRC)bridgestan.cpp)

$(BRIDGE_O) : $(BRIDGE_DEPS)
	@echo ''
	@echo '--- Compiling Stan bridge C++ code ---'
	@mkdir -p $(dir $@)
	$(COMPILE.cpp) $(OUTPUT_OPTION) $(LDLIBS) $<


ifneq ($(findstring allow-undefined,$(STANCFLAGS)),)
USER_HEADER ?= $(dir $(MAKECMDGOALS))user_header.hpp
USER_INCLUDE = -include $(USER_HEADER)
# Give a better error message if the USER_HEADER is not found
$(USER_HEADER):
	@echo 'ERROR: Missing user header.'
	@echo 'Because --allow-undefined is set, we need a C++ header file to include.'
	@echo 'We tried to find the user header at:'
	@echo '  $(USER_HEADER)'
	@echo ''
	@echo 'You can also set the USER_HEADER variable to the path of your C++ file.'
	@exit 1
endif

# generate .hpp file from .stan file using stanc
%.hpp : %.stan $(STANC)
	@echo ''
	@echo '--- Translating Stan model to C++ code ---'
	$(STANC) $(STANCFLAGS) --o=$(subst  \,/,$@) $(subst  \,/,$<)

%.o : %.hpp $(USER_HEADER)
	@echo ''
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) $(USER_INCLUDE) -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)

%_model.so : %.o $(BRIDGE_O) $(SUNDIALS_TARGETS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo ''
	@echo '--- Linking C++ code ---'
	$(LINK.cpp) -shared -lm -o $(patsubst %.o, %_model.so, $(subst \,/,$<)) $(subst \,/,$*.o) $(BRIDGE_O) $(LDLIBS) $(SUNDIALS_TARGETS) $(MPI_TARGETS) $(TBB_TARGETS)

.PHONY: docs
docs:
	$(MAKE) -C docs/ html

# build all test models at once
ALL_TEST_MODEL_NAMES = $(patsubst $(BS_ROOT)/test_models/%/, %, $(sort $(dir $(wildcard $(BS_ROOT)/test_models/*/))))
# these are for compilation testing in the interfaces
SKIPPED_TEST_MODEL_NAMES = syntax_error external
TEST_MODEL_NAMES := $(filter-out $(SKIPPED_TEST_MODEL_NAMES), $(ALL_TEST_MODEL_NAMES))
TEST_MODEL_LIBS = $(join $(addprefix $(BS_ROOT)/test_models/, $(TEST_MODEL_NAMES)), $(addsuffix _model.so, $(addprefix /, $(TEST_MODEL_NAMES))))

.PHONY: test_models
test_models: $(TEST_MODEL_LIBS)

.PHONY: clean
clean:
	$(RM) $(SRC)/*.o
	$(RM) test_models/**/*.so
	$(RM) $(join $(addprefix $(BS_ROOT)/test_models/, $(TEST_MODEL_NAMES)), $(addsuffix .hpp, $(addprefix /, $(TEST_MODEL_NAMES))))
	$(RM) bin/stanc$(EXE)

.PHONY: stan-update stan-update-version
stan-update:
	git submodule update --init --recursive

stan-update-remote:
	git submodule update --remote --init --recursive

# print compilation command line config
.PHONY: compile_info
compile_info:
	@echo '$(LINK.cpp) $(BRIDGE_O) $(LDLIBS) $(SUNDIALS_TARGETS) $(MPI_TARGETS) $(TBB_TARGETS)'



.PHONY: format format-check
format:
	clang-format -i src/*.cpp src/*.hpp src/*.h || true
	isort python || true
	black python || true
	julia --project=julia -e 'using JuliaFormatter; format("julia/")' || true
	air format R || true
	cd rust && cargo fmt || true

format-check:
	clang-format --dry-run --Werror src/*.cpp src/*.hpp src/*.h
	isort python --check
	black python --check
	julia --project=julia -e 'using JuliaFormatter; if !format("julia/", overwrite=false) exit(1) end'
	air format R --check
	cd rust && cargo fmt --check

# print value of makefile variable (e.g., make print-TBB_TARGETS)
.PHONY: print-%
print-%  : ; @echo $* = $($*) ;

# handles downloading of stanc
STANC_DL_RETRY = 5
STANC_DL_DELAY = 10
STANC3_TEST_BIN_URL ?=
STANC3_VERSION ?= v2.38.0

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

##
# This is only run if the `include` statements earlier fail to find a file.
# We assume that means the submodule is missing
##
$(MATH)make/% :
	@echo 'ERROR: Missing Stan submodules.'
	@echo 'We tried to find the Stan Math submodule at:'
	@echo '  $(MATH)'
	@echo ''
	@echo 'The most likely source of the problem is BridgeStan was cloned without'
	@echo 'the --recursive flag.  To fix this, run the following command:'
	@echo '  git submodule update --init --recursive'
	@echo ''
	@echo 'And try building again'
	@exit 1
