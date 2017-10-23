# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoredups:erasedups
HISTIGNORE=ls:ll:la:l:pwd:exit:mc:su:df:clear

# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
shopt -s dirspell
PROMPT_COMMAND='history -a'

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
export EDITOR=vim

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize


# Disable empty completions
#shopt -s no_empty_cmd_completion

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac


###########################################
#export STAR_VER="6.0.01"
#export STAR_EXE="/home/build/Distributions/HiDFT_STAR_${STAR_VER}_BUILDS/HiDFT-STAR"

function init_env {
  if [ $1 == "" ]; then
    echo "Please set arg for DEV_ROOT"
    exit
  fi
  export DEV_ROOT="$1"
  export DFT_BUILD_ROOT="$DEV_ROOT/defacto/src"
  export HIDFT_HOME="$DEV_ROOT/dist"
  export STAR_EXE="$DEV_ROOT/defacto/src/libstar/obj/test/debug64/star_debug64.exe"
  export TCLAPI_EXE="$DEV_ROOT/defacto/src/libtclapi/obj/test/debug64/tclapi_exec_debug64.exe"
  source $DEV_ROOT/build/source_me.sh
}

function so_tag {
  tag="ML"
  if [ "$1" != "" ]; then
    tag="$1"
  fi
  echo "Setting env for $tag"
#  tmp_dir="$HOME/tmp/svn_automerge"
  root_dir="$HOME/work/sandbox"
#  if [ -d $tmp_dir/$tag ]; then
#    root_dir="$tmp_dir"
#  fi
  init_env "$root_dir/$tag"
}

function so_tag_pwd {
  echo "Setting env with DEV_ROOT=$PWD"
  init_env $PWD
}

so_tag

if [ -f ~/.bash_ext ]; then
  . ~/.bash_ext
fi

export PATH=$HOME/soft/local/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/soft/local/lib64
#:$HOME/soft/local/lib readline ???

###########################################
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export PS1='\[\e]2;\w\a\033[00;33m\]\t \[\033[00;32m\]\u\[\033[00m\]@\[\033[00;32m\]\h\[\033[00m\]: \[\033[00;35m\]\w\[\033[00m\](\[\033[00;36m\]`git branch 2>/dev/null|cut -f2 -d\* -s | sed -e "s/ //"`\[\033[00m\])\n$'

# disable bracketted mode.
printf "\e[?2004l"

echo "$BASH_POST_RC" ; eval "$BASH_POST_RC"






