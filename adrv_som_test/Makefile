EXEC = test_rf
SYMBOLS = -DINFO
CFLAGS = -Wall $(SYMBOLS)
LIBS = -lfftw3 -liio -lm

all: $(EXEC)

$(EXEC): test_rf.c
	$(CC) $+ $(CFLAGS) $(LIBS) -o $(EXEC)

clean:
	rm -rf $(EXEC)