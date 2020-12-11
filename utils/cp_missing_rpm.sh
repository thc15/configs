#!/bin/bash

usage(){
    echo "$0 <src_dir> <dest_host>"
}

if [ $# -ne 2 ]; then
    usage
    exit
fi

SRC=$1
DEST=$2

echo "Copy rpm to $DEST:/tmp"

scp k1-mppapcie-netdev-dkms-*.noarch.rpm \
    k1-openssl-k1-no-cipher-*.x86_64.rpm \
    k1-board-mgmt-*.x86_64.rpm \
    k1-mppapcie-dkms-*.noarch.rpm \
    k1-lttng-modules-dkms-*.noarch.rpm \
    k1-mppaprobe-dkms-*.noarch.rpm \
    k1-bootloaders-*.x86_64.rpm \
    k1-fdt-host-*.x86_64.rpm \
    $DEST:/tmp

