#!/bin/bash -x

DST_HDD=( "/media/$USER/LACIE_P9220" "/mnt/data1" )

for hdd in "${DST_HDD[@]}"
do
        if [ ! -d $hdd ]; then
                continue
        fi

        $HOME/utils/backup.sh $HOME/images/ $hdd/images/
        $HOME/utils/backup.sh $HOME/Pictures/ $hdd/photos/
        $HOME/utils/backup.sh $HOME/Documents/ $hdd/documents/
        $HOME/utils/backup.sh $HOME/work/ $hdd/work/
done
