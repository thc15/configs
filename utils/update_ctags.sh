#!/bin/bash -x

ROOT="."
TAGS_FILE="$ROOT/.tags"
OPTS="-f $TAGS_FILE"

if [ ! -z "$2" ]; then
  TAGS_FILE="$2"
  # append mode
  OPTS="-a -f $TAGS_FILE"
fi


if [ -d "$1" ]; then
ROOT="$1"
fi
pushd $ROOT

find $ROOT -type f \
  -path "**/tmp*" -prune -o \
  -path "**/doc*" -prune -o \
  -path "**/build*" -prune -o \
  -not -name '*.mod.c' \
  -not -name '*.c.o' \
  -not -name '*.cmake' \
  -name "*.[chsS]" -print > $ROOT/cscope.files

find $ROOT -type f \
  -path "**/tmp*" -prune -o \
  -path "**/doc*" -prune -o \
  -path "**/build*" -prune -o \
  -not -name '*.mod.c' \
  -not -name '*.c.o' \
  -not -name '*.cmake' \
  -name "*.[ch]" -print \
  -name "*.[ch]pp" -print >> $ROOT/cscope.files

#cscope -b -q -k

ctags -L $ROOT/cscope.files $OPTS

rm -f $ROOT/cscope.files

popd
