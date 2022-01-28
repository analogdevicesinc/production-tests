SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

test_clkin()
{
    local SIG_TYPE CLKIN
    SIG_TYPE=$1

    sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_pps/rpi-ad9545-hmc7044.dtbo
    python3 m2k-signal_generator.py $SIG_TYPE &
    sleep 2
    sudo cat /sys/kernel/debug/clk/PLL1/PLL1 | grep "PLL status: Locked" && sudo cat /sys/kernel/debug/iio/iio\:device0/status | grep -B 10 "PLL1 & PLL2 Locked" | grep "CLKIN2"
    return $?
}

TEST_NAME="TEST_BACK_INPUTS"

echo "Testing Back Pannel"

TEST_ID="01"
SHORT_DESC="Test input REF_IN. Please make sure cable is connected!"
#CMD="wait_enter && test_clkin sqr"
CMD="wait_enter &&"
CMD+="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_default/rpi-ad9545-hmc7044.dtbo;"
CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py sqr &"
CMD+="sleep 3;" #maybe this way cat doesn't happen to fast and we can check lock state
CMD+="sudo cat /sys/kernel/debug/clk/PLL1/PLL1 | grep \"PLL status: Locked\" && sudo cat /sys/kernel/debug/iio/iio\:device0/status | grep -B 10 \"PLL1 & PLL2 Locked\" | grep \"CLKIN2\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test input PPS. Please make sure cable is connected!"
#CMD="wait_enter && test_clkin pps"
CMD="wait_enter &&"
CMD+="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_pps/rpi-ad9545-hmc7044.dtbo;"
CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py pps &"
CMD+="sleep 3;"
CMD+="$SCRIPT_DIR/rebind.sh;"
CMD+="sleep 7;"
CMD+="sudo cat /sys/kernel/debug/clk/Ref-BB-Div/Ref-BB-Div | grep \"Reference: Valid\" && sudo cat /sys/kernel/debug/iio/iio\:device0/status | grep -B 10 \"PLL1 & PLL2 Locked\" | grep \"CLKIN2\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"

TEST_ID="03" 
SHORT_DESC="Test input CH2. Please connect cables from M2K BNC Adapter Board to CH2 inputs"
CMD="wait_enter &&"
CMD+="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_no_ad/rpi-ad9545-hmc7044.dtbo;"
CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py sin &"
CMD+="sleep 3;"
CMD+="sudo cat /sys/kernel/debug/iio/iio\:device0/status | grep -B 10 \"PLL1 & PLL2 Locked\" | grep \"CLKIN1\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Test input CH3. Please connect cables from M2K BNC Adapter Board to both CH3 inputs"
CMD="wait_enter &&"
CMD+="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_no_ad/rpi-ad9545-hmc7044.dtbo;"
CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py sin &"
CMD+="sleep 3;"
CMD+="sudo cat /sys/kernel/debug/iio/iio\:device0/status | grep -B 10 \"PLL1 & PLL2 Locked\" | grep \"CLKIN0\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"
