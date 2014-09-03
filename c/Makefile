#Compiler
CC = gcc -O3

#compiler flags
# -g adds debug info to the executable file
# -Wall turns on most warnings from compiler
CFLAGS = -g -Wall

#Define locations of header files
OPTINC?= -I$(SAMTOOLS)/
INCLUDES= -I./src/ $(OPTINC) -rdynamic

# define library paths in addition to /usr/lib
#   if I wanted to include libraries not in /usr/lib I'd specify
#   their path using -Lpath, something like:
LFLAGS ?= -L$(SAMTOOLS)

# define any libraries to link into executable:
#   if I want to link in libraries (libx.so or libx.a) I use the -llibname
#   option, something like (this will link in libmylib.so and libm.so:
LIBS= -lbam -lpthread -lz

# define the C source files
SRCS=./src/bam_access.c

#Define test sources
TEST_SRC=$(wildcard ./tests/*_tests.c)
TESTS=$(patsubst %.c,%,$(TEST_SRC))

# define the C object files
#
# This uses Suffix Replacement within a macro:
#   $(name:string1=string2)
#         For each word in 'name' replace 'string1' with 'string2'
# Below we are replacing the suffix .c of all words in the macro SRCS
# with the .o suffix
#
OBJS = $(SRCS:.c=.o)

#Build target executable
COUNTER_TARGET=./bin/alleleCounter

#
# The following part of the makefile is generic; it can be used to
# build any executable just by changing the definitions above and by
# deleting dependencies appended to the file from 'make depend'
#

.PHONY: depend clean coverage test

.NOTPARALLEL: test

all: $(COUNTER_TARGET) test
	@echo  Binaries have been compiled.


$(COUNTER_TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) -o $(COUNTER_TARGET) $(OBJS) $(LFLAGS) $(LIBS) ./src/alleleCounter.c

#Unit Tests
test: $(CAVEMAN_TARGET)
test: CFLAGS += $(INCLUDES) $(OBJS) $(LFLAGS) $(LIBS)
test: $(TESTS)
	sh ./tests/runtests.sh

#Unit tests with coverage
coverage: CFLAGS += --coverage
coverage: test

valgrind:
	VALGRIND="valgrind --log-file=/tmp/valgrind-%p.log" $(MAKE)


# this is a suffix replacement rule for building .o's from .c's
# it uses automatic variables $<: the name of the prerequisite of
# the rule(a .c file) and $@: the name of the target of the rule (a .o file)
# (see the gnu make manual section about automatic variables)
.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) -c $<  -o $@

clean:
	$(RM) ./src/*.o *~ $(COUNTER_TARGET) ./bin/* ./tests/tests_log $(TESTS) ./src/*.gcda ./src/*.gcov ./src/*.gcno *.gcda *.gcov *.gcno ./tests/*.gcda ./tests/*.gcov ./tests/*.gcno

depend: $(SRCS)
	makedepend $(INCLUDES) $^

# DO NOT DELETE THIS LINE -- make depend needs it
