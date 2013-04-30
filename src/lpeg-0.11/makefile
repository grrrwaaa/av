LIBNAME = lpeg
LUADIR = /usr/include/lua5.1/

COPT = -O2
# COPT = -DLPEG_DEBUG -g

CWARNS = -Wall -Wextra -pedantic \
        -Waggregate-return \
	-Wbad-function-cast \
        -Wcast-align \
        -Wcast-qual \
	-Wdeclaration-after-statement \
	-Wdisabled-optimization \
        -Wmissing-prototypes \
        -Wnested-externs \
        -Wpointer-arith \
        -Wshadow \
	-Wsign-compare \
	-Wstrict-prototypes \
	-Wundef \
        -Wwrite-strings \
	#  -Wunreachable-code \


CFLAGS = $(CWARNS) $(COPT) -ansi -I$(LUADIR) -fPIC
CC = gcc

# For Linux
DLLFLAGS = -shared -fPIC
ENV = 

# For Mac OS
# ENV = MACOSX_DEPLOYMENT_TARGET=10.4
# DLLFLAGS = -bundle -undefined dynamic_lookup


FILES = lpvm.o lpcap.o lptree.o lpcode.o lpprint.o

lpeg.so: $(FILES)
	env $(ENV) $(CC) $(DLLFLAGS) $(FILES) -o lpeg.so

$(FILES): makefile

test: test.lua re.lua lpeg.so
	test.lua


lpcap.o: lpcap.c lpcap.h lptypes.h
lpcode.o: lpcode.c lptypes.h lpcode.h lptree.h lpvm.h lpcap.h
lpprint.o: lpprint.c lptypes.h lpprint.h lptree.h lpvm.h lpcap.h
lptree.o: lptree.c lptypes.h lpcap.h lpcode.h lptree.h lpvm.h lpprint.h
lpvm.o: lpvm.c lpcap.h lptypes.h lpvm.h lpprint.h lptree.h

