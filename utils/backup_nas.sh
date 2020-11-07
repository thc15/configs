#!/bin/bash

USER="pi"
NAS_IP="192.168.1.25"
RSYNC="rsync -atvuE --inplace --progress"

ssh $USER@$NAS_IP "ls /media/pi" | while read hdd; do
        $RSYNC $HOME/Pictures/ $USER@$NAS_IP:/$hdd/photos/
        $RSYNC $HOME/Documents/ $USER@$NAS_IP:/$hdd/documents/
        $RSYNC $HOME/work/ $USER@$NAS_IP:/$hdd/work/
done
