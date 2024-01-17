#!/bin/bash 

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_NAV"

TEST_ID="01"
SHORT_DESC="Button event mapped" 
CMD="timeout 1 evtest /dev/input/by-path/platform-gpio_keys-event | grep 'Input device name: \"gpio_keys\"' > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="double press BT0 - timeout 10 seconds" 
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 1 (EV_KEY), code 183 (KEY_F13), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="double press BT1 - timeout 10 seconds" 
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 1 (EV_KEY), code 184 (KEY_F14), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="double press BT2 - timeout 10 seconds" 
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 1 (EV_KEY), code 185 (KEY_F15), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="05"
SHORT_DESC="double press BT3 - timeout 10 seconds" 
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 1 (EV_KEY), code 186 (KEY_F16), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="06"
SHORT_DESC="toggle twice SW0 - timeout 10 seconds"
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 5 (EV_SW), code 13 (SW_LINEIN_INSERT), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="07"
SHORT_DESC="toggle twice SW1 - timeout 10 seconds"
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 5 (EV_SW), code 1 (SW_TABLET_MODE), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="08"
SHORT_DESC="toggle twice SW2 - timeout 10 seconds"
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 5 (EV_SW), code 2 (SW_HEADPHONE_INSERT), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="09"
SHORT_DESC="toggle twice SW3 - timeout 10 seconds"
CMD="timeout 10 evtest /dev/input/by-path/platform-gpio_keys-event | grep -m 1 \"type 5 (EV_SW), code 3 (SW_RFKILL_ALL), value 0\" > /dev/null"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="10"
SHORT_DESC="test LED0-3" 
CMD="echo heartbeat | tee /sys/class/leds/led0:green/trigger > /dev/null;"
CMD+="sleep 0.1 && echo heartbeat | tee /sys/class/leds/led1:green/trigger > /dev/null;"
CMD+="sleep 0.1 && echo heartbeat | tee /sys/class/leds/led2:green/trigger > /dev/null;"
CMD+="sleep 0.1 && echo heartbeat | tee /sys/class/leds/led3:green/trigger > /dev/null;"
CMD+="YES_no 'Are LEDs 0-3 blinking ? '"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

echo none | tee /sys/class/leds/led[0-3]\:green/trigger > /dev/null

: #if reached this point, ensure exit code 0
