IOP_BIN  = tsqdrv.irx

IOP_INCS +=
IOP_CFLAGS  += -std=c99
IOP_LDFLAGS +=

IOP_OBJS = tsqdrv.o imports.o
IOP_LIBS =

all: $(IOP_BIN)

clean:
	rm -f $(IOP_BIN) $(IOP_OBJS)

rebuild: clean all


include $(PS2SDK)/Defs.make
include $(PS2SDK)/samples/Makefile.iopglobal
