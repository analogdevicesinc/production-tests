#!/bin/bash

SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
source "$SCRIPT_DIR/../lib/utils.sh"

URI="local:"
DEV="adis16470"

if ! iio_info -u "$URI" 2>/dev/null | grep -q "iio:device[0-9]\+: $DEV"; then
  echo "ERROR: IMU '$DEV' not found in IIO context"
  exit 2
fi

echo "IMU found: $DEV"

ax=$(iio_attr --uri "$URI" -c "$DEV" accel_x raw 2>/dev/null)
ay=$(iio_attr --uri "$URI" -c "$DEV" accel_y raw 2>/dev/null)

if [[ "$ax" == "0" && "$ay" == "0" ]]; then
  echo "ERROR: IMU present but accel values are zero"
  exit 1
else
  echo "IMU accel values: ax=$ax ≠ 0, ay=$ay ≠ 0"
fi

exit 0
