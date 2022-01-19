
SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_CLK_OUTPUTS"

clk_test()
{
    local reg_nr CLK_FREQ
    local ret1=0
    reg_nr=$1

    sudo echo $reg_nr 0xc1 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access
    CLK_FREQ=$( python3 $SCRIPT_DIR/m2k-frequency-estimator.py )
    echo $CLK_FREQ
    sudo echo $reg_nr 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access

    if [[ $CLK_FREQ -ne 10000000 ]]; then
        ret1=1
    fi

    return $(( ret1 ))
}

echo "Disabling all outputs"
echo 0x00c8 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch11
echo 0x00d2 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch12
echo 0x00dc 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch14
echo 0x00e6 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch13
echo 0x00f0 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch08
echo 0x00fa 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch10
echo 0x0104 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch06
echo 0x010e 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch04
echo 0x0118 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch01
echo 0x0122 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch02
echo 0x012c 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch03
echo 0x0136 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch05
echo 0x0140 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch09
echo 0x014a 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch07

TEST_ID="01"
SHORT_DESC="TEST OUTPUT CHANNEL 01. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x0118"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="TEST OUTPUT CHANNEL 02. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x0122"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="TEST OUTPUT CHANNEL 03. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x012c"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="TEST OUTPUT CHANNEL 04. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x010e"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="TEST OUTPUT CHANNEL 05. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x0136"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="TEST OUTPUT CHANNEL 06. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x0104"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="TEST OUTPUT CHANNEL 07. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x014a"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="08"
SHORT_DESC="TEST OUTPUT CHANNEL 08. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x0f0"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="09"
SHORT_DESC="TEST OUTPUT CHANNEL 09. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x0140"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="10"
SHORT_DESC="TEST OUTPUT CHANNEL 10. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x00fa"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

# TEST_ID="11"
# SHORT_DESC="TEST OUTPUT CHANNEL 11. Make sure cable is connected!"
# CMD="wait_enter && clk_test 0x00c8"
# run_test $TEST_ID "$SHORT_DESC" "$CMD"

# TEST_ID="12"
# SHORT_DESC="TEST OUTPUT CHANNEL 12. Make sure cable is connected!"
# CMD="wait_enter && clk_test 0x00d2"
# run_test $TEST_ID "$SHORT_DESC" "$CMD"

# TEST_ID="13"
# SHORT_DESC="TEST OUTPUT CHANNEL 13. Make sure cable is connected!"
# CMD="wait_enter && clk_test 0x00e6"
# run_test $TEST_ID "$SHORT_DESC" "$CMD"

# TEST_ID="14"
# SHORT_DESC="TEST OUTPUT CHANNEL 14. Make sure cable is connected!"
# CMD="wait_enter && clk_test 0x00dc"
# run_test $TEST_ID "$SHORT_DESC" "$CMD"

