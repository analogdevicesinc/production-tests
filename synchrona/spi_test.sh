SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_SPI_COMMUNICATION"


TEST_ID="01"
SHORT_DESC="TEST SPI - Make sure the adapter is connected!"
CMD="dtoverlay -r;"
CMD+="dtoverlay $SCRIPT_DIR/rpi-ad9545-hmc7044.dtbo;"
CMD+="cat /sys/kernel/debug/clk/PLL0/PLL0 | grep \"PLL status: Unlocked\";"
CMD+="cat /sys/kernel/debug/iio/iio\:device0/status | grep -A 10 PLL1 | grep PLL2"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

