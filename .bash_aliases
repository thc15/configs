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
alias fd='find . -iname '
alias rm='\rm -i '
alias ka='\killall -s 9 '
alias ll='ls -al'
alias rm_log='rm -f logfile_*'

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

#
alias ot='$HOME/utils/open_ut.sh '

vfd()
{
#    gvim `find -P -03 . -type f -name "*$1*"`
    gvim `find -O3 -P . -path ./lib -prune -o -path obj -prune -o -path ./libtest -prune -o -path ./framework/lib -prune -o \
     -name '*.o*' -prune -o -name '*.d' -prune -o -type f -iname "*$1*" -print`
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
alias cdb='cd $DEV_ROOT/build'
alias hg='history | grep -ni '
alias pg='ps -ef | grep -ni '

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
    gnome-terminal --geometry=175x75+0+0 --working-directory="$DEV_ROOT" \
      --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "' \
      --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "' \
      --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "'
  fi
}

function dbg {
  if [ "$1" != "" ]; then
    gnome-terminal --geometry=240x73+200+0 \
                   --working-directory="$DEV_ROOT/" \
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

