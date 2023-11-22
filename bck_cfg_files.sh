#!/bin/bash

D=$(dirname `realpath "$0"`)

files=(.vimrc  .bashrc  .inputrc .tmux.conf .zshrc)

for f in ${files[*]}; do
    cp -f $HOME/$f $D
    echo "$f done"
done
