#!/bin/bash

DST_HDD=( "/media/LACIE_P9220" )

for hdd in "${DST_HDD[@]}"
do
        if [ ! -f $hdd ]; then
                continue
        fi

        $HOME/utils/backup.sh $HOME/Pictures/ $hdd/photos/
        $HOME/utils/backup.sh $HOME/Documents/ $hdd/documents/
        $HOME/utils/backup.sh $HOME/work/ $hdd/work/
done
