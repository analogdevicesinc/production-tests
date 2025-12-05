#!/bin/bash

daplink_mount=$(ls -d /media/analog/DAPLINK* 2>/dev/null | sort -V | tail -n 1)
mountpoint=$(mount | awk -v path="$daplink_mount" '$0 ~ path { for (i=1; i<=NF; i++) if ($i ~ path) print $i }')
if [ -z "$mountpoint" ]; then
    echo "No mountpoint found for DAPLINK"
    exit 1
fi
echo "Mountpoint: $mountpoint" 

inotifywait -m -e unmount "$mountpoint" | (
    rsync -ahv --progress /home/analog/production-tests/main_tests/swiot/swiot_firmware/swiot_prod.hex "$mountpoint"
    sync

    while read -r directory event filename; do
        echo "$mountpoint has been unmounted. Waiting for it to be mounted again..."
        start_time=$(date +%s)
        while true; do
            if mountpoint -q "$mountpoint"; then
                echo "$mountpoint has been remounted."
                pkill -P $$ inotifywait  # Send SIGTERM to child inotifywait process
                break
            fi
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))
            if [ "$elapsed_time" -ge 30 ]; then
                echo "Timeout reached. $mountpoint did not remount within 30 seconds."
                pkill -P $$ inotifywait  # Send SIGTERM to child inotifywait process
                break
            fi
            sleep 1 
        done
    done
)

if [[ -f "${mountpoint}/FAIL.txt" ]]; then
    echo "FAILED"
else
    echo "no fail.txt found. SUCCESS"
fi

