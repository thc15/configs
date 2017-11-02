#!/bin/bash

function usage {
echo 
echo $0 dir 
echo 
exit
}

[[ $# -ne 1 ]] && usage

du --max-depth=1 --exclude=.snapshot/* -k $1 | sort -nr


