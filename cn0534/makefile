TARGETS = power_check

override CFLAGS += -std=gnu99 -Wall -Wextra -MMD -MP
override LDFLAGS += -liio -lm -lfftw3 -lpthread

SRC_DIR ?=./src
BIN_DIR ?=./bin
OBJ_DIR ?=./obj

SRCS := $(shell find $(SRC_DIR) -name *.c)
OBJS := $(SRCS:%=$(OBJ_DIR)/%.o)
DEPS := $(OBJS:.o=.d)

MKDIR_P ?= mkdir -p

.PHONY: all clean


all: $(BIN_DIR)/$(TARGETS)

$(OBJ_DIR)/%.c.o : %.c
	$(MKDIR_P) $(dir $@)
	$(CC) -g $(CFLAGS) -c $< -o $@

$(BIN_DIR)/$(TARGETS): $(OBJS)
	$(MKDIR_P) $(dir $@)
	$(CC) -g $(OBJS) -o $@ $(CFLAGS) $(LDFLAGS)

clean:
	rm -rf $(BIN_DIR) $(OBJ_DIR)

-include $(DEPS)
