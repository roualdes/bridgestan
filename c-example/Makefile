# Tell the top-level makefile which relative path to use
BRIDGE=../src/bridgestan.cpp
include ../Makefile

../stan/full/libfull_model.so: ../stan/full/full_model.so
	cp ../stan/full/full_model.so ../stan/full/libfull_model.so

example$(EXE): example.c ../stan/full/libfull_model.so
	gcc -c -I ../src example.c -o example.o
	$(LINK.c) -o example$(EXE) example.o -Wl,-rpath ../stan/full -L ../stan/full -lfull_model
	$(RM) example.o

# static linking version

# this is very similar to the core Make rule in BridgeStan, just with AR instead of LINK
%_model.a: %.hpp $(BRIDGE_O) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	@echo '--- Compiling C++ code ---'
	$(COMPILE.cpp) $(CXXFLAGS_PROGRAM) -fPIC $(CXXFLAGS_THREADS) -x c++ -o $(subst  \,/,$*).o $(subst \,/,$<)
	@echo '--- Creating static library ---'
	$(AR) -cvq $(patsubst %.hpp, %_model.a, $(subst \,/,$<)) $(subst \,/,$*.o) $(BRIDGE_O)
	$(RM) $(subst  \,/,$*).o


example_static$(EXE):  example.c ../stan/full/full_model.a
	gcc -c -I ../src example.c -o example.o
	$(LINK.cpp) -o example_static$(EXE) example.o ../stan/full/full_model.a $(LDLIBS) $(LIBSUNDIALS) $(MPI_TARGETS) $(TBB_TARGETS)
	$(RM) example.o
