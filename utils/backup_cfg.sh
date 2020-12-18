#!/bin/bash -x

source list_cfg_files.sh

DEST_DIR=`mktemp -d`

git clone $REPO -b $BRANCH $DEST_DIR

cd $DEST_DIR

for f in "${listFiles[@]}"
do
	cp -Rf $f $DEST_DIR/
done
CI=`printf '%(%Y-%m-%d %H:%M:%S)T\n' -1`

git add -A
git commit -a -m "$CI"
git push origin $BRANCH

cd -
