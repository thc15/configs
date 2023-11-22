# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="avit"
RPROMPT="[%D{%f/%m/%y} | %D{%L:%M:%S}]"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
#DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf autojump)

source $ZSH/oh-my-zsh.sh

# User configuration

export TERM=xterm-256color
export MANPATH="/usr/local/man:$MANPATH"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export CONAN_CACERT_PATH=/etc/ssl/certs
unset LESS

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
unalias gl
unalias ll

alias v='vim'
alias vd='vimdiff '
alias vc='vim -p `git diff --name-only --relative | uniq`'
alias vl='git diff --name-only HEAD^ | xargs -o vim'
alias ll='ls -al'
alias pg='ps aux | grep'
alias rm='\rm -i'
alias d='cd ..'
alias cdm='cd $HOME/work/mediatek'
alias cdl='cd $HOME/work/img-application-sw-linux/libcamera'
alias cdi='cd $HOME/work/prg-camsens-sw/ipp-gst-transform'
alias r='vim $HOME/Documents/r.txt'
alias connect_rpi='ssh pi@10.131.176.113'
alias connect_r3a='ssh rock@10.131.176.59'
alias gr='grep -nri'
alias killbg="jobs -p | sed -e 's/ +\|- //' | awk '{print \$2}' | xargs kill -9"
alias killsshRockPI="kill -9 `pg ssh | grep -e "rock\|pi" | awk '{print $2}'`"
#tmux
alias tk='tmux kill-session -t '
alias ta='tmux attach -t '
#git
alias gd='git difftool -t vimdiff -y -M '
alias gg='git grep'
alias gl='git log --oneline --pretty=format:"%C(yellow)%h %Cblue%>(12)%ad %Cgreen%<(7)%aN%Cred%d %Creset%s"'
alias gw='git whatchanged'
alias gb='git branch --sort=-committerdate'
alias grv='git remote -v'

unsetopt CDABLE_VARS
unsetopt AUTO_NAME_DIRS

function fd()
{
     find . -path '*proc*' -prune -o -iname $1 -print
}

function df_()
{
    du  -d 1 $1 | sort -h
}

function dirdiff()
{
    # Shell-escape each path:
    DIR1=$(printf '%q' "$1"); shift
    DIR2=$(printf '%q' "$1"); shift
    vim $@ -c "DirDiff $DIR1 $DIR2"
}

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
if [[ -f $HOME/bin/proxy_set.sh ]]; then
	source $HOME/bin/proxy_set.sh
fi
