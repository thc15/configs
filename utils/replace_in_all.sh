#!/bin/bash

usage() {
  echo "Usage $0 [dir] [old]  [new]"
}

if [[ $# -ne 3 ]]; then
   usage
   exit 1
fi

DIR=$1
OLD=$2
NEW=$3

find $DIR -type f -name "*.[ch]" -exec sed -i "s/$OLD/$NEW/g" {} \;
