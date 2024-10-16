# Tell the top-level makefile which relative path to use
BS_ROOT=..
include ../Makefile

MODEL?=full
CC = gcc

../test_models/$(MODEL)/lib$(MODEL)_model.so: ../test_models/$(MODEL)/$(MODEL)_model.so
	cp ../test_models/$(MODEL)/$(MODEL)_model.so ../test_models/$(MODEL)/lib$(MODEL)_model.so

example$(EXE): example.c ../test_models/$(MODEL)/lib$(MODEL)_model.so
	$(CC) -c -I ../src example.c -o example.o
	$(LINK.c) -o example$(EXE) example.o -Wl,-rpath ../test_models/$(MODEL) -L ../test_models/$(MODEL) -l$(MODEL)_model
	$(RM) example.o

# static linking version

# this is very similar to the core Make rule in BridgeStan, just with AR instead of LINK
%_model.a: %.hpp $(BRIDGE_O) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)
	@echo '--- Creating static library ---'
	$(AR) -rcs $(patsubst %.hpp, %_model.a, $(subst \,/,$<)) $(subst \,/,$*.o) $(BRIDGE_O)
	$(RM) $(subst  \,/,$*).o


example_static$(EXE):  example.c ../test_models/$(MODEL)/$(MODEL)_model.a
	$(CC) -c -I ../src example.c -o example.o
	$(LINK.cpp) -o example_static$(EXE) example.o ../test_models/$(MODEL)/$(MODEL)_model.a $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	$(RM) example.o

example_runtime$(EXE): runtime_loading.c
	$(CC) -I ../src runtime_loading.c -o example_runtime$(EXE) -ldl
