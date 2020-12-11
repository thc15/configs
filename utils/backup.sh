#!/bin/bash

DEV_ROOT="/work1/tcostis/work"
COMP_LIST=( "${DEV_ROOT}/runtime/ethernet" \
	"${DEV_ROOT}/libraries/rpc-firmwares" \
	"${DEV_ROOT}/linux_buildroot/buildroot" \
	"${DEV_ROOT}/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom" \
	"${DEV_ROOT}/rdtools/ethernet" )

BKP_DIR="/work1/tcostis/tmp/backup"
mkdir -p $BKP_DIR

for d in "${COMP_LIST[@]}"
do
	echo $d
	cd $d
	LOG="$(basename `dirname $d`)_$(basename $d).log"
	mv ${BKP_DIR}/${LOG} ${BKP_DIR}/${LOG}.old
	git diff master -- . > "${BKP_DIR}/${LOG}"
done

