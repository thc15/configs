#!/bin/bash


#echo "Looking for C++ file in $DEV_ROOT"
#TAG_FILELIST="/tmp/tags_filelist.txt"

#find $DEV_ROOT -name '*.[ch]*' -not -path .git -not -path .svn -not -path obj \
#      -not -path stubobj -not -path dist -not -path build -not -path "*/linux_x86*" \
#       -not -path bin -not -path "*/golden*" -not -path "*/libtest*" -not -path "*/rtl_out*" > $TAG_FILELIST

echo "Generating ctags for $DEV_ROOT"
#--sort=yes
ctags -R --c++-kinds=+p --fields=+ilaS --extra=+q  --excmd=number \
       --exclude=.git \
       --exclude=.svn \
       --exclude=build \
       --exclude=bin \
       --exclude=dist \
       --exclude=obj \
       --exclude=stubobj \
       --exclude=golden \
       --exclude=libtest \
       --exclude=rtl_out \
       --exclude=scripts \
       --exclude=linux_x86 \
       --exclude=*.v* \
       --exclude=*.tcl \
       --exclude=*.log \
       --exclude=*.gold* \
       --exclude=*.mak \
       --exclude=$DEV_ROOT/3rdparty/boost \
       --exclude=$DEV_ROOT/3rdparty/verific/examples \
       --exclude=$DEV_ROOT/3rdparty/verific/test \
       --exclude=$DEV_ROOT/defacto/src/framework/libswig/test \
       -f $DEV_ROOT/tags $DEV_ROOT

echo "Generating  $DEV_ROOT/.clang_complete"
# -V -L $TAG_FILELIST
 #cd $DEV_ROOT
 #echo "Building clang_complete file"
 #make CC='~/.vim/bin/cc_args.py gcc' CXX='~/.vim/bin/cc_args.py g++' -B
 #cd -

 echo "-pthread
-std=c++11
-g
-DDEFACTO_INCLUDE
-DCOMPIL_DEBUG
-DHIDFT64
-DHIDFTLMGR10
-DENABLE_TRACE

-I3rdparty/verific/lib/*/src
-Idefacto/src/lib*/src
-Idefacto/src/framework/lib*/src" > $DEV_ROOT/.clang_complete




