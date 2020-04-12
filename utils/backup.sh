#!/bin/bash -x

usage() {
  local p=`basename $0`
  echo "Usage: $p <SRC> <DST>" 
  echo
}

if [ $# -ne 2 ]; then
 usage
 exit 1
fi

SRC_DIR=$1
DST_DIR=$2


rsync -atvuE --inplace --progress $SRC_DIR $DST_DIR
