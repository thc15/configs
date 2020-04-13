#!/bin/bash -x

XFER="cp -fpuv"
TOP="$HOME/Pictures/"
SRC="/media/thomas/disk/"

if [ ! -d $SRC/DCIM ]; then
        exit -1
fi

Y=$(date +%Y)
M=$(date +%m)_$(date +%b)
D=$(date +%d)
DEST_DIR="$TOP/$Y/$M/$D"
DEST_DIR_JPG="$DEST_DIR/JPG"

mkdir -p $DEST_DIR
mkdir -p $DEST_DIR_JPG

for d in $SRC/DCIM/*; do
        for f in $d/*.RAF; do
                ff=$(basename -- "$f")
                extension="${ff##*.}"
                filename="${f%.*}"
                $XFER $f $DEST_DIR
                mv $filename.JPG $DEST_DIR_JPG
        done
        for f in $d/*; do
                $XFER $f $DEST_DIR
        done
done

$HOME/utils/backup.sh $TOP /mnt/data/photos/
$HOME/utils/backup.sh $TOP /mnt/data1/photos/
