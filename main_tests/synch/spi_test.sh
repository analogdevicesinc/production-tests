SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_SPI_COMMUNICATION"
FAIL_COUNT=0


TEST_ID="01"
SHORT_DESC="TEST SPI - Make sure the adapter is connected!"
CMD="wait_enter &&"
CMD+="dtoverlay $SCRIPT_DIR/rpi-ad9545-hmc7044.dtbo;"
CMD+="sleep 3;"
CMD+="cat /sys/kernel/debug/clk/PLL0/PLL0 | grep \"PLL status: Unlocked\";"
CMD+="cat /sys/kernel/debug/iio/iio\:device0/status | grep -A 10 PLL1 | grep PLL2"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

failed_no
answer=$?
exit $answer
