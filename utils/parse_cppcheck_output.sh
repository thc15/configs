#!/bin/bash 

function usage {
echo 
echo $0 cppcheck_logfile
echo 
exit
}

[[ $# -ne 1 ]] && usage

LOG_FILE=$1

#for l in `cat $LOG_FILE`
#cat  $LOG_FILE | while read line
while read l; do
# file="${l%\\n}"
#file="${file%]*}"
  echo $l
line=`echo $l | cut -f1 -d']'`
file=`echo $line | sed -e 's/:/ +/g' | cut -f2 -d'['`
echo $file
f=`echo $file | cut -f1 -d' '`

if [ ! -f $f ]; then
  f=`basename $f`
  ln=`echo $file | cut -f2 -d' '`
  echo "Searching file $f"
  file=`find -O3 -P . -path ./lib -prune -o -path obj -prune -o -path ./libtest -prune -o -path ./framework/lib -prune -o -type f -name $f -print`
  file="$file +$ln"
fi
gvim -geom 130x80+600+0 -p $file

 # select yn in "y" "n"; do
 read -u 3 -p "Continue ? " yn
    case $yn in
        n ) exit;;
    esac
done 3<&0 <$LOG_FILE

