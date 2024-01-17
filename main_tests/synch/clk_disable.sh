
SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_CLK_OUTPUTS"

echo $TEST_NAME

clk_test()
{
    local reg_nr CLK_FREQ
    local ret1=0
    reg_nr=$1

    sudo echo $reg_nr 0xc1 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access
    CLK_FREQ=$( python3 $SCRIPT_DIR/m2k-frequency-estimator.py 0)
    echo $CLK_FREQ
    sudo echo $reg_nr 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access

    if [[ $CLK_FREQ -ne 10000000 ]]; then
        ret1=1
    fi

    return $(( ret1 ))
}

clk_test_cmos()
{
    local reg_nr CLK_FREQ OPT reg_mod
    local ret1=0
    reg_nr=$1
    OPT=$2
    reg_mod=$3

    if [ $OPT -eq 0 ]; then
        sudo echo $reg_mod 0x19 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access
    else
        sudo echo $reg_mod 0x1A > /sys/kernel/debug/iio/iio\:device0/direct_reg_access
    fi
    sudo echo $reg_nr 0xc1 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access
    CLK_FREQ=$( python3 $SCRIPT_DIR/m2k-frequency-estimator.py )
    echo $CLK_FREQ
    sudo echo $reg_nr 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access

    if [[ $CLK_FREQ -ne 10000000 ]]; then
        ret1=1
    fi

    return $(( ret1 ))
}

sudo dtoverlay -r
sudo dtoverlay $SCRIPT_DIR/rpi-ad9545-hmc7044.dtbo

lsblk | grep "/media/analog/M2k"

if [ $? -ne 0 ]; then
    echo "Your ADALM2000 device is not connected! Please connect it and then continue with the testing procedure."
    exit 255
fi

echo "Disabling all outputs"
echo 0x00c8 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch11
echo 0x00d2 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch12
echo 0x00dc 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch14
echo 0x00e6 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch13
echo 0x00f0 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch08 - CMOS
echo 0x00fa 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch10
echo 0x0104 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch06 - CMOS
echo 0x010e 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch04
echo 0x0118 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch01
echo 0x0122 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch02
echo 0x012c 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch03
echo 0x0136 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch05 - CMOS
echo 0x0140 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch09
echo 0x014a 0xc0 > /sys/kernel/debug/iio/iio\:device0/direct_reg_access #ch07 - CMOS

TEST_ID="01"
SHORT_DESC="TEST OUTPUT CHANNEL 01 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0118 0 0x0120"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="TEST OUTPUT CHANNEL 01 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0118 1 0x0120"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="TEST OUTPUT CHANNEL 02 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0122 1 0x012a"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="TEST OUTPUT CHANNEL 02 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0122 0 0x012a"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="TEST OUTPUT CHANNEL 03 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x012c 1 0x0134"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="TEST OUTPUT CHANNEL 03 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x012c 0 0x0134"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="TEST OUTPUT CHANNEL 04 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x010e 0 0x0116"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="08"
SHORT_DESC="TEST OUTPUT CHANNEL 04 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x010e 1 0x0116"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="09"
SHORT_DESC="TEST OUTPUT CHANNEL 05 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0136 0 0x013e"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="10"
SHORT_DESC="TEST OUTPUT CHANNEL 05 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0136 1 0x013e"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="11"
SHORT_DESC="TEST OUTPUT CHANNEL 06 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0104 1 0x010c"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="12"
SHORT_DESC="TEST OUTPUT CHANNEL 06 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0104 0 0x010c"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="13"
SHORT_DESC="TEST OUTPUT CHANNEL 07 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x014a 1 0x0152"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="14"
SHORT_DESC="TEST OUTPUT CHANNEL 07 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x014a 0 0x0152"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="15"
SHORT_DESC="TEST OUTPUT CHANNEL 08 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0f0 0 0x00f8"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="16"
SHORT_DESC="TEST OUTPUT CHANNEL 08 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0f0 1 0x00f8"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="17"
SHORT_DESC="TEST OUTPUT CHANNEL 09 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0140 0 0x0148"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="18"
SHORT_DESC="TEST OUTPUT CHANNEL 09 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x0140 1 0x0148"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="19"
SHORT_DESC="TEST OUTPUT CHANNEL 10 - P. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x00fa 1 0x102"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="20"
SHORT_DESC="TEST OUTPUT CHANNEL 10 - N. Make sure cable is connected!"
CMD="wait_enter && clk_test_cmos 0x00fa 0 0x102"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="21"
SHORT_DESC="TEST OUTPUT CHANNEL 11. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x00c8"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="22"
SHORT_DESC="TEST OUTPUT CHANNEL 12. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x00d2"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="23"
SHORT_DESC="TEST OUTPUT CHANNEL 13. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x00e6"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="24"
SHORT_DESC="TEST OUTPUT CHANNEL 14. Make sure cable is connected!"
CMD="wait_enter && clk_test 0x00dc"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

