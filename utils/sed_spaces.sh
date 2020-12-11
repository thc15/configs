#!/bin/bash -x

LOG="/tmp/syntax_check.log"

sed -n '/[^ ]\*[^ ]/p' $1 > $LOG
sed -n '/[^ ]+[^ ]/p' $1 | grep -v ++ >> $LOG
