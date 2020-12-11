#!/bin/bash -x

if [ -z "$DEV_ROOT" ]; then
  DEV_ROOT="/work1/tcostis/work"
fi

REPOS=( "${DEV_ROOT}/runtime/" \
    "${DEV_ROOT}/rdtools/" \
    "${DEV_ROOT}/tools_coolidge/" \
    "${DEV_ROOT}/linux_buildroot/" \
    "${DEV_ROOT}/linux_toolchain/" \
    "${DEV_ROOT}/linux_toolchain_coolidge/" )

for d in "${REPOS[@]}"
do
    if [ -d $d ];  then
            cd $d
            git remote update --prune
            git submodule foreach git remote update --prune
            cd -
    fi
done

