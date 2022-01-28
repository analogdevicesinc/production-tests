SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

test_clkin()
{
    local SIG_TYPE
    SIG_TYPE=$1

    sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_pps/rpi-ad9545-hmc7044.dtbo
    python3 m2k-signal_generator.py $SIG_TYPE &
    sleep 1
    sudo cat /sys/kernel/debug/clk/PLL1/PLL1 | grep -q "PLL status Locked" && sudo cat /sys/kernel/debug/clk/iio/iio\:device0/status | grep -q "PLL1 & PLL2 Locked"
    return $?
}

TEST_NAME="TEST_BACK_INPUTS"

echo"Testing Back Pannel"

TEST_ID="01"
SHORT_DESC="Test input REF_IN. Please make sure cable is connected!"
CMD="wait_enter && test_clkin sqr"
# CMD="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_default/rpi-ad9545-hmc7044.dtbo &&"
# CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py sqr &"
# CMD+="sleep 1 &&" #maybe this way cat doesn't happen to fast and we can check lock state
# CMD+="sudo cat /sys/kernel/debug/clk/PLL1/PLL1 | grep -q \"PLL status Locked\" && sudo cat /sys/kernel/debug/clk/iio/iio\:device0/status | grep -q \"PLL1 & PLL2 Locked\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test input PPS. Please make sure cable is connected!"
CMD="wait_enter && test_clkin pps"
# CMD="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_pps/rpi-ad9545-hmc7044.dtbo &&"
# CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py pps &"
# CMD+="$SCRIPT_DIR/rebind.sh &&"
# CMD+="sleep 4 &&"
# CMD+="wait_enter && sudo cat /sys/kernel/debug/clk/Ref-BB-Div/Ref-BB-Div | grep -q \"Reference: Valid\" && sudo cat /sys/kernel/debug/clk/iio/iio\:device0/status | grep -q \"PLL1 & PLL2 Locked\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"

TEST_ID="03" 
SHORT_DESC="Test input CH2. Please connect cables from M2K BNC Adapter Board to CH2 inputs"
CMD="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_no_ad/rpi-ad9545-hmc7044.dtbo &&"
CMD+="wait_enter && echo \"Please press enter after you are done setting the cable\" &&"
CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py sin &"
CMD+="sudo cat /sys/kernel/debug/clk/iio/iio\:device0/status | grep -q \"PLL1 & PLL2 Locked\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"

TEST_ID="04"
#dtoverlay first 
SHORT_DESC="Test input CH3. Please connect cables from M2K BNC Adapter Board to CH3 inputs"
CMD="sudo dtoverlay -r && sudo dtoverlay /boot/overlays/sync_no_ad/rpi-ad9545-hmc7044.dtbo &&"
CMD+="wait_enter && echo \"Please press enter after you are done setting the cable\" &&"
CMD+="python3 $SCRIPT_DIR/m2k-signal_generator.py sin &"
CMD+="sudo cat /sys/kernel/debug/clk/iio/iio\:device0/status | grep -q \"PLL1 & PLL2 Locked\""
run_test "$TEST_ID" "$SHORT_DESC" "$CMD"
