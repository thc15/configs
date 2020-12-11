#!/bin/bash -x

PATH=$(echo $PATH | awk -v RS=: -v ORS=: '!($0 in a) {a[$0]; print}')
PATH=$(echo $PATH | sed 's/::/:/g' | sed 's/\s:/:/g')
