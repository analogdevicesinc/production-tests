 #!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_SOM_ADRV_PHY"

TEST_ID="01"
SHORT_DESC="Check if both ADRV chip 1 is detected"
CMD="cat /sys/bus/iio/devices/iio*/name | grep -q adrv9009-phy"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Check if both ADRV chip 2 is detected"
CMD="cat /sys/bus/iio/devices/iio*/name | grep -q adrv9009-phy-b"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

 : #if reached this point, ensure exito code 0
