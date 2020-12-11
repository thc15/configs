#!/bin/bash

cd ~ || exit 1
DIRTOCHECK="/work1/$USER/work/"
LSOFCMD="lsof -V $DIRTOCHECK"
LSOF=$($LSOFCMD)
LSOFRET=$?

if [[ "$LSOFRET" -eq 1 && "$LSOF" == "lsof: no file system use located: $DIRTOCHECK" ]] ; then
	echo "Unmounting $DIRTOCHECK..."
	fusermount -u "$DIRTOCHECK"
else
	$LSOFCMD
	cd - || exit 1
	exit $LSOFRET
fi
