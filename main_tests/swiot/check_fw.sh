#!/bin/bash

# Numberumber of attempts
num_attempts=10

# Loop to try the iio_info command multiple times
for ((attempt=1; attempt <= num_attempts; attempt++)); do
    # Run iio_info  and grep the firmware version
    output=$(sudo iio_info -u ip:$1 | grep "Backend description string")

    # Check if "wethlink-production" is present
    if echo "$output" | grep -q "lwip"; then
        echo "Production firmware detected."
        exit 0  # Exit the loop and script since we found the desired firmware
    else if echo "$output" | grep -q "release"; then
	echo "Regular firmware detected."
	exit 0	
    fi
    fi

    if [[ $attempt == $num_attempts ]]; then
	    exit 1
    fi
	
    # Sleep for a short duration before the next attempt
    sleep 1
done



# Check for regular firmware
if echo "$output" | grep -q "lwip"; then
    echo "Regular firmware detected"
else
    echo "Junk firmware/could not make iio_info connection"
fi
