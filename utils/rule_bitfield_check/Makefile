# SPDX-License-Identifier: GPL-2.0

ROOT := $(DEV_ROOT)/
HW_LIBS := $(ROOT)/rdtools/hw_libs/ethernet/eth_parser

CC = clang

CFLAGS += -fms-extensions -std=c11 -Wall -g -O1 -I./include -I$(HW_LIBS)/include

CFLAGS += -I$(ROOT)/rdtools/devimage/toolchain_default/machine/k1-elf/include
CFLAGS += -I$(ROOT)/linux_toolchain_coolidge/linux/include

BIN = rule_bitfield_check
SRCS = $(wildcard src/*.c)
OBJS = $(SRCS:.c=.o)
OBJS += $(HW_LIBS)/src/mppa_hw_eth_parser.o

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(BIN): $(OBJS)
	$(CC) $(LDFLAGS) $^ -o $@

all: $(BIN)

clean:
	rm -Rf $(BIN) $(OBJS)

PHONY: clean
