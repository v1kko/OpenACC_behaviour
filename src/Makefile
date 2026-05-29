SRC_FILES := $(wildcard *.f90)
CASE ?= .
COMPILER ?= ftn
SUBMIT_COMMAND ?=
EXE_FILES := $(patsubst %.f90,$(CASE)/%,$(SRC_FILES))
RUN_FILES := $(patsubst %.f90,$(CASE)/%.run,$(SRC_FILES))

all: $(EXE_FILES)
run: $(RUN_FILES)

$(CASE):
	mkdir $@

$(CASE)/%:%.f90 | $(CASE)
	-$(COMPILER) -o $@ $^ 2>&1 | tee $@.compilation_out

$(CASE)/%.run:$(CASE)/%
	-$(SUBMIT_COMMAND) ./$^ 2>&1 | tee $^.run_out

$(CASE)/gpu_aware_mpi.run:$(CASE)/gpu_aware_mpi
	-$(MPI_SUBMIT_COMMAND) ./$^ 2>&1 | tee $^.run_out

$(CASE)/gpu_aware_mpi_slicing.run:$(CASE)/gpu_aware_mpi_slicing
	-$(MPI_SUBMIT_COMMAND) ./$^ 2>&1 | tee $^.run_out

clean:
	rm $(EXE_FILES)
