#!/bin/bash -x

source list_cfg_files.sh

DEST_DIR=`mktemp -d`

git clone $REPO -b $BRANCH $DEST_DIR

cd $DEST_DIR

function cmp_file()
{
    local f=$1
    local dest_file=$2
    if [[ ! -f $dest_file ]]; then
        cp -f $f $dest_file
    elif [[ -n $(diff $f $dest_file) ]]; then
        <dev/tty vimdiff $f $dest_file
    fi
}

function cp_file()
{
    local f=$1
    local dest_dir=$2
    if [[ -d $f ]]; then
        find "$f/" -type f | while IFS= read line; do
           cmp_file $line $dest_dir/$line
        done
    else
           cmp_file $f $dest_dir/$f
    fi
}

for f in "${listFiles[@]}"
do
    cp_file $f $HOME
done

cd -
