SRC_FILES := $(wildcard *.f90)
EXE_FILES := $(patsubst %.f90,%,$(SRC_FILES))
COMPILER ?= ftn

all: $(EXE_FILES)

%:%.f90
	$(COMPILER) -o $@ $^

clean:
	rm $(EXE_FILES)
