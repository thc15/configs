# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

HISTCONTROL=ignoredups:erasedups
HISTIGNORE=ls:ll:la:l:pwd:exit:mc:su:df:clear

# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
shopt -s dirspell
shopt -s cdspell
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND ;} history -a"

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
export EDITOR=vim
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking 
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold 
export LESS_TERMCAP_me=$'\E[0m'           # end mode 
export LESS_TERMCAP_ue=$'\E[0m'           # end underline 
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

export DEV_ROOT="/work1/tcostis/work/"
#export TERM='rxvt-unicode-256color'
export TERM='tmux-256color'

export DISABLE_AUTO_TITLE="true"

#
#if [ "$HOSTNAME" = "pallas" ]; then
#if [ -e /usr/share/terminfo/s/screen-256color ]; then
#        export TERM='screen-256color'
#else
#        export TERM='xterm-256color'
#fi
#fi

#if [[ $PYTHONPATH != *"$HOME/.local/lib/python2.7/site-packages"* ]]; then
#  export PYTHONPATH=$HOME/.local/lib/python2.7/site-packages:$PYTHONPATH
#fi

###########################################
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

function last_dirs {
  pwd |rev| awk -F / '{print $1,$2}' | rev | sed s_\ _/_
}

export PS1='\[\e]2;\w\a\033[00;33m\]\t \[\033[00;32m\]\u\[\033[00m\]@\[\033[00;32m\]\h\[\033[00m\]:\[\033[00;35m\]>$(last_dirs)\[\033[00m\](\[\033[00;36m\]`git branch 2>/dev/null|cut -f2 -d\* -s | sed -e "s/ //"`\[\033[00m\])\n$'

[[ -s ~/.autojump/etc/profile.d/autojump.sh ]] && source ~/.autojump/etc/profile.d/autojump.sh
[[ -s /work/common/arcanist/arcanist.sh ]] && source /work/common/arcanist/arcanist.sh

unset PERL_MM_OPT

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export KALRAY_ENV_SCRIPTS_DIR=${KALRAY_ENV_SCRIPTS_DIR:-/work1/$USER/kalray-envs}
if [ -d ${KALRAY_ENV_SCRIPTS_DIR} ]; then
   export PATH="${KALRAY_ENV_SCRIPTS_DIR}${PATH:+:$PATH}"
   if [ -f ${KALRAY_ENV_SCRIPTS_DIR}/kalrayrc-completion.sh ]; then
        .  ${KALRAY_ENV_SCRIPTS_DIR}/kalrayrc-completion.sh
   fi
fi

