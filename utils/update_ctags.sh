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
       -f $DEV_ROOT/tags $DEV_ROOT

#################################################################################
echo "Generating cscope for $DEV_ROOT"

TMP_CSCOPE=`mktemp`
find  $DEV_ROOT -name '*.[ch]*' | grep -v -E '(.git|.svn|libtest|linux_x86|build|golden|examples|dist|doc|\.com)' > $TMP_CSCOPE
$HOME/soft/local/usr/bin/cscope -Rbq -i $TMP_CSCOPE -f $DEV_ROOT/cscope.out

#################################################################################

echo "Generating .clang_complete files"
ROOT="$DEV_ROOT/"
UPDATE_DONE=0

cd $ROOT
for m in `find $ROOT -name Makefile`  # | grep -v -E 'examples|doc|tcl|edit|expat|metis|xalan'`
do
    D=`dirname $m`
    if [ "$D" == "$ROOT" ]; then continue; fi
    if [ "$D" == "$ROOT/framework" ]; then continue; fi
    TMP=`echo $D | grep libtest`
    if [ -n "$TMP" ]; then continue; fi

    echo $D
    cd $D
    if [ ! -f $D/.clang_complete ]; then
      echo "Generating .clang_complete for $D"
      make ADD_CPPFLAGS=-DDISABLE_LICENSES CC="$HOME/.vim/bin/cc_args.py g++" CXX="$HOME/.vim/bin/cc_args.py g++" CPP="$HOME/.vim/bin/cc_args.py g++" -i -b -B -j 8 -s
      UPDATE_DONE=1
     fi
    cd $ROOT
done

if [ "$UPDATE_DONE" -eq "1" ]; then
  make clean -C $DEV_ROOT/3rdparty/verific
  make clean -C $DEV_ROOT/3rdparty/expat
  make clean -C $DEV_ROOT/3rdparty/tcl
fi
