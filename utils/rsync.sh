#!/bin/zsh

rsync -aLv --exclude 'chromium*' --exclude 'X11' $0 $1
