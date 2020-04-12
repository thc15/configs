#
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# User specific aliases and functions
alias d='cd ..'
alias fd='find . -iname '
alias rm='\rm -i '
alias ll='ls -al'

function ssht () {
	/usr/bin/ssh -X -t $@ "$HOME/bin/tmux attach || $HOME/bin/tmux new";
}

function color-ssh() {
	#trap "$HOME/utils/colorterm.sh" INT EXIT
	$HOME/utils/colorterm.sh ssh
	\ssh $*
	$HOME/utils/colorterm.sh
}

# completion + alias
#compdef _ssh color-ssh=ssh
alias ssh=color-ssh

# vim
alias vl='vim -c "cd `git rev-parse --show-toplevel`" `git whatchanged -n 1 --oneline | sed "1d" | sed -e "s/.*\s//"`'
alias v='vim'
alias vd='vimdiff -d '


# dev
alias ag='ag -a '
alias hg='history | grep -ni '
alias pg='ps -ef | grep -ni '

# git
alias gd='git difftool -t vimdiff -y '
alias gw='git whatchanged'
alias gb='git branch '
alias grv='git remote -v'
alias gl='git log --graph --abbrev-commit --pretty=oneline --decorate -n 50'
