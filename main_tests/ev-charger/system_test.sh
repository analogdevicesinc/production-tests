#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

ret=0
serial="/dev/ttyACM0"
bd_rate="57600"


if [ ! -e "$serial" ]; then
  echo "Error: Serial port $serial does not exist."
  exit 1
fi

stty -F $serial $bd_rate cs8 -cstopb -parenb
read -p  "Please press the reset button on the device and press 'ENTER' when done..."

cat $serial | while read -r line; do

  if echo "$line" | grep -q "DEBUG: TEST: Self-test passed"; then
    echo "DEBUG: TEST: Self-test passed"
    echo_green "PASSED"
    break

  elif echo "$line" | grep -q "DEBUG: TEST: Self-test failed"; then
    echo "DEBUG: TEST: Self-test failed"
    echo_red "FAILED"
    break

  fi

done

