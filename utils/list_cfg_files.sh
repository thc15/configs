#!/bin/bash

REPO="ssh://git@github.com/thc15/configs"
BRANCH="home"

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

