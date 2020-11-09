#!/bin/bash -x

USER="pi"
NAS_IP="192.168.1.25"
RSYNC="rsync -atvuE --inplace --progress"
MOUNT_PT="/media/pi"

ssh $USER@$NAS_IP "ls $MOUNT_PT" | while read hdd; do
        $RSYNC $HOME/Pictures/ $USER@$NAS_IP:$MOUNT_PT/$hdd/photos/
        $RSYNC $HOME/Documents/ $USER@$NAS_IP:$MOUNT_PT/$hdd/documents/
        $RSYNC $HOME/work/ $USER@$NAS_IP:$MOUNT_PT/$hdd/work/
done
