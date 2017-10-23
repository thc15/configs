#
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='\grep --color=auto'
    alias fgrep='\fgrep --color=auto'
    alias egrep='\egrep --color=auto'
fi

# User specific aliases and functions
alias d='cd ..'
alias fd='find . -name '
alias rm='\rm -i '
alias ka='\killall -s 9 '
alias ll='ls -al'

# grep
alias gr='grep -nri'
alias ac="ag --cpp --ignore linux_x86 "
alias acy="ag -G '.*\.(c|cpp|h|hpp|java|y)$' --ignore linux_x86 "

# vim
# cd ~/.vim/bundle/YouCompleteMe && ./install.py --clang-completer
alias vl='gvim -c "cd `git rev-parse --show-toplevel`" `git whatchanged -n 1 --oneline | sed "1d" | sed -e "s/.*\s//"`'
alias vd='gvimdiff'
#alias vp='gvim -geom 130x80'
alias vp='vim -g -geom 130x80'

vfd()
{
#    gvim `find -P -03 . -type f -name "*$1*"`
    gvim `find -O3 -P . -path ./lib -prune -o -path obj -prune -o -path ./libtest -prune -o -path ./framework/lib -prune -o \
     -name '*.o*' -prune -o -name '*.d' -prune -o -type f -name "*$1*" -print`
#extension="${filename##*.}"
}

vdd()
{
  file1="$1/$3"
  file2="$2/$3"
  gvimdiff $file1 $file2
}

# dev
alias cdr='cd $DEV_ROOT'
alias cdv='cd $DEV_ROOT/3rdparty/verific/lib/verilog/src'
alias cds='cd $DEV_ROOT/defacto/src'
alias cdt='cd $DEV_ROOT/defacto/src/libtest/test/testcases/defacto'
alias cdb='cd $DEV_ROOT/build'
alias hg='history | grep -ni '
alias pg='ps -ef | grep -ni '

mks () {
#  DISABLE_LICENSE="yes"
  MK="make -j5 -s"
  export ADD_CPPFLAGS=-DDISABLE_LICENSES
  if [ "$#" == "0" ]; then
    echo "Building libcmd libtclmd libstar"
    pushd .
    cd $DEV_ROOT/defacto/src
    ${MK} -C "$DEV_ROOT/defacto/src/framework/libcmd"
    ${MK} -C "$DEV_ROOT/defacto/src/libtclcmd" && ${MK} -C "$DEV_ROOT/defacto/src/libstar"
    popd
  elif [ "$1" == "all" ]; then
    echo "Building all $DEV_ROOT/defacto/src + framework"
    ${MK} -C "$DEV_ROOT/defacto/src/framework" all
    ${MK} -C "$DEV_ROOT/defacto/src" all
  else
   if [ -d "$DEV_ROOT/defacto/src/framework/$1" ]; then
     echo "Building $1"
     ${MK} -C "$DEV_ROOT/defacto/src/framework/$1"
   elif [ -d "$DEV_ROOT/defacto/src/$1" ] ; then
     echo "Building $1"
     ${MK} -C "$DEV_ROOT/defacto/src/$1"
   else
     echo "$1 not found"
   fi
  fi
}

mk_release() {
  unset ADD_CPPFLAGS
  echo $ADD_CPPFLAGS
  cd $DEV_ROOT/defacto/src
  DIST=release make -j5 -C libstar
  DIST=release make -j5 -C libtclapi
#  ARCH=32 DIST=release make -j5 -C libstar
  if [ -f $DEV_ROOT/defacto/src/libstar/obj/test/release64/star_release64.exe ]; then
    DEST=/home/thomas/tmp/bin/`date +%Y%m%d_%H%M`
    mkdir -p $DEST
# cp $DEV_ROOT/defacto/src/libstar/obj/test/release/star_release.exe $DEST
    cp $DEV_ROOT/defacto/src/libstar/obj/test/release64/star_release64.exe $DEST
    cp $DEV_ROOT/defacto/src/libtclapi/obj/test/release64/tclapi_release64.exe $DEST
  else
    echo "Binary NOT copied"
  fi
  cd -
}

alias utd='ut_debug -i --debug '
alias utall='cd $DEV_ROOT/defacto/src ; dev_so ; mks all && { ut_run ; cd framework ; dev_so ; ut_run ; ut_res ; cd .. ; ut_res ; }'
alias utprod='cd $DEV_ROOT/defacto/src ; dev_so ; mks libtclcmd && mks libstar  && mks libtclapi  && mks libptsi  && mks libscan; ut_prod_reduced'

utr () {
  mks $1 && ut_run $1 && ut_res
}
complete -C "ut_debug --_complete" utd

function dev_so {
  export DFT_BUILD_ROOT=$PWD
  export HIDFT_HOME=$DEV_ROOT/dist
  CURRDIR=$PWD
  while [[ "$PWD" != "/" ]]
  do
    if [[ -e ./build/source_me.sh ]]
    then
      . ./build/source_me.sh
      break
    fi
    cd ..
  done
  cd $CURRDIR
}

function oe {
  if [ "$1" != "" ] && [ "$COLORTERM" == "gnome-terminal" ]; then
    export env="$1"
    gnome-terminal --geometry=175x75+0+0 --working-directory="$HOME/work/sandbox/$1/defacto/src" \
      --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "' \
      --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "' \
      --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "'
  fi
}

function dbg {
  if [ "$1" != "" ]; then
    gnome-terminal --geometry=240x73+200+0 \
                   --working-directory="$DEV_ROOT/defacto/src" \
                   --title="DBG $1" \
                   -e "cgdb $1"
  fi
}

function nl {
  bz=$1
  if [ "$bz" == "" ]; then
    gvim -p /tmp/log_`date +%Y%m%d_%H%M%S`
  else
    mkdir -p $HOME/tmp/bugs/bug_$bz
    gvim -p $HOME/tmp/bugs/bug_$bz/log
  fi
}

# git
#alias git="/usr/bin/git"   #override PATH /opt/rh/devtoolset-2/root/usr/bin
alias git="$HOME/soft/local/bin/git"   #override PATH /opt/rh/devtoolset-2/root/usr/bin
alias gg='git grep'
alias gd='git difftool -t gvimdiff -y'
alias gw='git whatchanged'
function gws {
  CUR="$1"
  PREV="$CUR^"
  if [ "$2" == "" ]; then
    git difftool -t gvimdiff -y $PREV $CUR
  elif [ -f $2 ]; then
    git difftool -t gvimdiff -y $PREV $CUR -- $2
  else
    echo "$2 NOT found"
  fi
}
alias gba='git branch -a'
alias grv='git remote -v'
alias gl='git log --graph --abbrev-commit --pretty=oneline --decorate -n 50'
alias gdl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative "  #master..branchX

#svn
alias sl="svn log | perl -l40pe 's/^-+/\n/' | less"
alias sba='svn ls svn+ssh://cheesecake/svn/dev/branches --verbose'
sdt () {
  svn diff svn+ssh://cheesecake/svn/trunk svn+ssh://cheesecake/svn/dev/branches/$1
}


