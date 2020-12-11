#!/bin/bash

if [ -z "$DEV_ROOT" ]; then
  DEV_ROOT="/work1/tcostis/work"
fi

GIT_DIRS="
    "${DEV_ROOT}/runtime/ethernet" \
    "${DEV_ROOT}/tools_coolidge" \
    "${DEV_ROOT}/linux_toolchain" \
    "${DEV_ROOT}/linux_buildroot" \
"

date
for i in $GIT_DIRS ; do 
  echo $i
  pushd $i
  git remote update && git remote update --prune
  git submodule foreach --recursive git remote update --prune
  git gc && git submodule foreach --recursive git gc
  git prune && git submodule foreach --recursive git prune
  popd
done

date
