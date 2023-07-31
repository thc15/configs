#!/bin/bash -x

usage() {
    echo "$0 <path>"
}

if [[ $# -ne 1 ]]; then
    usage
    exit -1
fi

DIR=$1

ctags -R --c-kinds=+p --exclude=.git \
    --exclude=vendor --exclude=node_modules \
    --exclude=db --exclude=build \
    --exclude=.vscode  --exclude=log $DIR
