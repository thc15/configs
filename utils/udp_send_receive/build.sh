#!/bin/sh
set +e

kvx-elf-gcc -O3 -Wall -Wextra -Wno-unused-parameter \
    -ggdb -g \
    -o udpreceiver1 udpreceiver1.c \
    net.c

kvx-elf-gcc -O3 -Wall -Wextra -Wno-unused-parameter \
    -ggdb -g  \
    -o udpsender udpsender.c \
    net.c
