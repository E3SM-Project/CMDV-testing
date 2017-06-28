.PHONY: clean tests
# first target is default unless .DEFAULT_GOAL is defined
.DEFAULT_GOAL := all

OBJ = *


all: clean tests

tests:  $(OBJ)
	# compile test code if necessary 
	touch .success

clean:
	-rm .success



