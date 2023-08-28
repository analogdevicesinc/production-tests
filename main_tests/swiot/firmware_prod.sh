#!/bin/bash

# find path for daplink

# cp the hex file to daplink

mountpoint=$(mount | awk '/DAPLINK/ { for (i=1; i<=NF; i++) if ($i ~ "/DAPLINK") print $i }')
mountpoint_files=0

if [[ $mountpoint != "" ]]; then
	mountpoint_files=$(ls -1 $mountpoint | wc -l)
fi

until [[ $mountpoint != "" ]] && [[ $mountpoint_files != 0 ]]
do
	read -p "Plug in the DAPLINK USB cable and press ENTER"

	mountpoint=$(mount | awk '/DAPLINK/ { for (i=1; i<=NF; i++) if ($i ~ "/DAPLINK") print $i }')
	if [[ $mountpoint != "" ]]; then
		mountpoint_files=$(ls -1 $mountpoint | wc -l)
	fi
done

echo $mountpoint

if [[ $mountpoint == ""  ]]; then
	echo "DAPLINK not mounted!"
	exit 1
fi

# Start monitoring the mountpoint
inotifywait -m -e unmount "$mountpoint" | (
    rsync -ah -v --progress ~/production-tests/main_tests/swiot/swiot_firmware/swiot_prod.hex $mountpoint
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
            if [ "$elapsed_time" -ge 60 ]; then
                echo "Timeout reached. $mountpoint did not remount within 30 seconds."
                pkill -P $$ inotifywait  # Send SIGTERM to child inotifywait process
                break
            fi
            sleep 1  # Adjust the interval as needed
        done
    done
)

# verify if there s a FAIL.txt file

if [[ -f "${mountpoint}/FAIL.txt" ]]; then
	echo "FAILED"
	exit 1;
else
	echo "no fail.txt found. SUCCESS"
fi


## return error if something fails
