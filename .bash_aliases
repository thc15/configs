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
alias l='ls -al'
alias win='rdesktop -x 0x80 winapp -k fr -d kalray -g 1400x960'
alias slack='/snap/slack/current/usr/bin/slack'
alias zoom='LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/snap/zoom-client/current/zoom /snap/zoom-client/current/zoom/zoom'


function duse() {
	du -h --max-depth=1 "$1" | sort -h
}

function ssht () {
	/usr/bin/ssh -X -t $@ "tmux attach-session -t default || tmux new";
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
# cd ~/.vim/bundle/YouCompleteMe && ./install.py --clang-completer
alias vl='vim -c "cd `git rev-parse --show-toplevel`" `git whatchanged -n 1 --oneline | sed "1d" | sed -e "s/.*\s//"`'
#alias vd='gvimdiff -geom 200x70'
alias r='vim $HOME/docs/dev'
alias vd='vimdiff -d '
#alias vmap='vp $DEV_ROOT/rdtools/machine/build/map/coolidge.cluster.map'
#alias veth='vp $DEV_ROOT/rdtools/machine/build/linux_headers/devices/ethernet_coolidge.h'
alias vmap='vim -p $DEV_ROOT/ltc/workspace/devimage/toolchain_default/toolroot/opt/kalray/accesscore/kalray_internal/machine/headers/linux/devices/eth*.h $DEV_ROOT/ltc/workspace/devimage/toolchain_default/toolroot/opt/kalray/accesscore/kalray_internal/machine/headers/elf/machine/devices/eth*.dev $HOME/tmp/coolidge.v1.map'

alias v='vim'
alias vc='vim -p `git diff --name-only --relative | uniq`'
vg()
{
        vp `git grep --files-with-matches $1`
}

vfd()
{
#    gvim `find -P -03 . -type f -name "*$1*"`
    vim -g -geom 170x70 `find -O3 -P . -path ./lib -prune -o -path obj -prune -o -path ./libtest -prune -o -path ./framework/lib -prune -o \
     -name '*.o*' -prune -o -name '*.d' -prune -o -type f -iname "*$1*" -print`
#extension="${filename##*.}"
}

vdd()
{
  file1="$1/$3"
  file2="$2/$3"
  vimdiff $file1 $file2
}

ddiff()
{
    # Shell-escape each path:
    DIR1=$(printf '%q' "$1"); shift
    DIR2=$(printf '%q' "$1"); shift
    echo $DIR1 $DIR2
    for files in $(diff -rq $DIR1 $DIR2 | grep 'differ$'|sed "s/^Files //g;s/ differ$//g;s/ and /:/g"); do
        vimdiff ${files%:*} ${files#*:};
    done
 #   vim $@ -c "DirDiff $DIR1 $DIR2"
}

# dev
alias ag='ag -a '
alias hg='history | grep -ni '
alias pg='ps -ef | grep -ni '
alias tk='tmux kill-session -t '
alias ta='tmux attach -t '
alias tn='tmux new -s '
alias tl='tmux list-sessions'
alias cdw='cd $DEV_ROOT'
alias cdlc='cd $DEV_ROOT/ltc/linux'
alias cdo='cd $DEV_ROOT/ltc/odp'
alias cdv='cd $DEV_ROOT/ltc/linux_valid'
alias cde='cd $DEV_ROOT/csw/ethernet'
alias cdt='cd $DEV_ROOT/csw/fdt/device-trees'
alias cda='cd $DEV_ROOT/csw/aci_hw_sw/tests/mppa/Ethernet'
alias k1r='$DEV_ROOT/csw/devimage/toolchain_default/toolroot/usr/local/k1rdtools/kalray_internal/machine/bin/k1reg'

alias yi='sudo yum install -y'
alias ys='sudo yum search'

function ggl {
   ag -l "$1" | xargs ag "$2"
}

function nodup {
  if [ "$1" != "" ]; then
    P="$1"
    echo -n $P | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}'
  fi
}


function install_rpc_firmware {
	cd $DEV_ROOT/libraries/rpc-firmwares
	source $DEV_ROOT/linux_buildroot/kEnv/k1tools/.switch_env
	make RPCFIRMWARE_PATH=$DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/odp_firmware-1.0.0/rpc-firmwares uninstall install
	make RPCFIRMWARE_PATH=$DEV_ROOT/linux_buildroot/kEnv/k1tools/rpc-firmwares uninstall install
	OUTPUT_FILE=$DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/linux-custom/drivers/misc/kalray/mppa_rpc_odp/rpc_odp.h $DEV_ROOT/linux_buildroot/update_odp.sh
	if [ -f $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/odp_firmware-1.0.0/.stamp_built ]; then
		rm -f $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug/build/odp_firmware-1.0.0/.stamp_built
	fi
	cd -
}

function build_kernel {
	cd $DEV_ROOT/linux_buildroot/images/k1bio_console_legacy_debug
	source $DEV_ROOT/linux_buildroot/kEnv/k1tools/.switch_env
	unset PERL_MM_OPT; make  ARCH=k1 HAL_INCLUDE=$DEV_ROOT/linux_toolchain/devimage/toolchain_linux/kalray_internal/include/ MOS_INCLUDE=$DEV_ROOT/linux_toolchain/devimage/toolchain_linux/toolroot/usr/local/k1-linux/k1-linux-sysroot/usr/include/mOS -j8
	cd -
}

function oes {
  TARGET_SSH="mppa-dev084"
  if [ "$1" != "" ]; then
    TARGET_SSH="$1"
  fi
  echo "Launching ssh on $TARGET_SSH"
  gnome-terminal --geometry=175x75+0+0 --working-directory="$DEV_ROOT" \
  --title="SSH $TARGET_SSH" \
  --tab -e "ssh $USER@$TARGET_SSH" --profile="ssh" \
  --tab -e "ssh $USER@$TARGET_SSH" --profile="ssh" \
  --tab -e "ssh $USER@$TARGET_SSH" --profile="ssh"
#    --tab -e 'bash -c "export BASH_POST_RC=\"so_tag $env\" ; exec bash "' \
}

function dbg {
  if [ "$1" != "" ]; then
    gnome-terminal --geometry=240x73+200+0 \
                   --working-directory="$DEV_ROOT/" \
                   --title="DBG $1" \
                   -e "cgdb $1"
  fi
}

function cg {
	PORT=$1
	if [ -z "$PORT" ]; then
		PORT="10000"
	fi
    if [ -z "$2" ]; then
        cgdb -d 'kvx-gdb' -- -ex "attach-mppa $PORT" --
    else
        cgdb -d 'kvx-gdb' -- -ex "attach-mppa $PORT" -ex 'tb gdb_mmu_enabled' -ex 'c' --
    fi
}

function gg() {
    p=$1;
    git --no-pager grep $p & git submodule foreach 'git --no-pager grep '$p'; true';
}

# git
alias gd='git difftool -t vimdiff -y -M '
alias gw='git whatchanged'
function gdd {
  CUR="$1"
  PREV="$CUR^"
  if [ "$2" == "" ]; then
    git difftool -t vimdiff -y $PREV $CUR
  elif [ -f $2 ]; then
    git difftool -t vimdiff -y $PREV $CUR -- $2
  else
    echo "$2 NOT found"
  fi
}
alias gb='git branch --sort=-committerdate'
alias gfa='git fetch -a'
alias grv='git remote -v'
alias gl='git log --oneline --format="%C(auto) %h %an / %cD / %s"'

#kpatch xxx.patch --cc anyone@else.com --in-reply-to 2017datesandletters@somehostname
function kpatch () {
  patch=$1
  shift
  git send-email \
    --cc-cmd="./scripts/get_maintainer.pl --norolestats $patch" \
    $@ $patch
}

alias gnome-control-center='env XDG_CURRENT_DESKTOP=GNOME gnome-control-center'
