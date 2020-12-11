#!/bin/bash -x

if [ ! -d "$DEV_ROOT" ]; then
  echo "Dev_ROOT not set"
  exit 1
fi

echo "Update kernel tags"
KROOT=$DEV_ROOT/linux_toolchain_coolidge/linux

cd $KROOT
ARCH=kvx KBUILD_SRC=$KROOT srctree=$KROOT ./scripts/tags.sh tags

cd -

