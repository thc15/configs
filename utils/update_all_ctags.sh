#!/bin/bash -x

if [ -z "$DEV_ROOT" ]; then
  DEV_ROOT="/work1/tcostis/work"
fi
TAGS_FILE="$DEV_ROOT/.tags"

rm -f $TAGS_FILE

COMP_LIST=( \
    "${DEV_ROOT}/csw/hw_libs/" \
    "${DEV_ROOT}/tools/barebox/" \
    "${DEV_ROOT}/csw/mppa_dma" \
    "${DEV_ROOT}/ltc/odp" \
    "${DEV_ROOT}/csw/machine/build/linux_headers/devices" )

for d in "${COMP_LIST[@]}"
do
    if [ -d $d ];  then
        $HOME/utils/update_ctags.sh $d $TAGS_FILE
    fi
done

#pushd ${DEV_ROOT}/linux_toolchain/linux
#ARCH=k1 SUBARCH=k1b COMPILED_SOURCE=1 ./scripts/tags.sh tags
pushd ${DEV_ROOT}/ltc/linux
ARCH=kvx SRCARCH=kvx ./scripts/tags.sh tags
#COMPILED_SOURCE=1 
popd
