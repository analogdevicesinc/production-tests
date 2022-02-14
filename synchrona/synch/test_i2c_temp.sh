SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_ADT7422"

TEST_ID="01"
SHORT_DESC="Checking for adt7422"
CMD="dtoverlay -r && dtoverlay /boot/overlays/sync_default/rpi-ad9545-hmc7044.dtbo;"
CMD="cat /sys/class/hwmon/hwmon2/device/name | grep adt7422"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Checking for temperature"
CMD="TEMP=\$(cat /sys/class/hwmon/hwmon2/device/temp1_input);"
CMD+="[[ \$TEMP -ge 20 ]] && [[ \$TEMP -le 85 ]]"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
