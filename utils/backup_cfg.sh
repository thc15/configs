#!/bin/bash -x


USER_GIT="thc15"
REPO="ssh://git@github.com/$USER_GIT/configs"
BRANCH="home"
DEST_DIR=`mktemp -d`

listFiles=( "$HOME/.vimrc*" \
 	     "$HOME/.gitconfig" \
 	     "$HOME/.gitignore_global" \
 	     "$HOME/.Xresources" \
 	     "$HOME/.Xsessionrc" \
 	     "$HOME/.ackrc" \
 	     "$HOME/.bash_aliases" \
 	     "$HOME/.bash_profile" \
 	     "$HOME/.bashrc" \
 	     "$HOME/.inputrc" \
 	     "$HOME/.tmux.conf" \
 	     "$HOME/.cgdbrc" \
 	     "$HOME/.config/i3" \
 	     "$HOME/.config/rofi" \
 	     "$HOME/docs" \
	     "$HOME/utils" )


git clone $REPO -b $BRANCH $DEST_DIR

cd $DEST_DIR

for f in "${listFiles[@]}"
do
	cp -Rf $f $DEST_DIR/
done
CI=`printf '%(%Y-%m-%d %H:%M:%S)T\n' -1`

git add -A
git commit -a -m "$CI"
git push origin $BRANCH

cd -
