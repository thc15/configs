#!/bin/bash

if [ -n "$TMUX" ]; then
  if [ "$1" == "ssh" ]; then
    tmux select-pane -P 'bg=#192436'
  else
    tmux select-pane -P 'bg=#000000'
  fi;
else
  if [ "$1" == "ssh" ]; then
    printf '\033]11;#192436\007'
  else
    #printf '\033]11;#282c34\007'
    printf '\033]11;#000000\007'
  fi
fi
