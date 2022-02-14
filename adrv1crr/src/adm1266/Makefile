export SRCS
export MAIN
EXE=exe
MAIN=
IDIR =library
CC=gcc
CFLAGS=-I$(IDIR)

ODIR=obj

LIBS=-lm

_SRCS = adi_pmbus.c	\
	adm1266.c	\
	adm1266_pmbus_interface.c

SRCS = $(addprefix $(IDIR)/,$(_SRCS))
_DEPS = adi_pmbus.h adm1266.h adm1266_pmbus_interface.h
DEPS = $(addprefix $(IDIR)/,$(_DEPS))

_OBJ = $(SRCS:.c=.o)
OBJ = $(addprefix $(ODIR)/,$(notdir $(_OBJ)))


$(ODIR)/%.o:$(IDIR)/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(EXE):$(OBJ)
	$(CC) $(OBJ) $(ODIR)/$(MAIN).o -o $(EXE) $(CFLAGS) $(LIBS)

all: 
	$(MAKE) blackbox
	$(MAKE) monitor
	$(MAKE) load_fw
	$(MAKE) prod_flash

objdir: 
	@mkdir -p $(ODIR) 

blackbox: objdir
	$(MAKE) compile MAIN=Blackbox EXE=Blackbox

monitor: objdir
	$(MAKE) compile MAIN=Monitor EXE=Monitor

load_fw: objdir
	$(MAKE) compile MAIN=load_fw_config EXE=load_fw_config

prod_flash: objdir
	$(MAKE) compile MAIN=production_flash EXE=production_flash

compile:
	$(CC) -c $(MAIN).c -o $(ODIR)/$(MAIN).o $(CFLAGS)
	$(MAKE) $(EXE)

.PHONY: clean

clean:
	@rm -rf $(ODIR)

re : clean all