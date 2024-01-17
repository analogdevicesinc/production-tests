#!/bin//bash 

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


MODE="$1"

case $MODE in
            "Firmware and memory test")
            echo_blue "Programming production test firmware..."
            # $SCRIPT_DIR/firmware_prod.sh &&
            # $SCRIPT_DIR/check_fw.sh &&
            echo_blue "Memory testing..."
            tty=/dev/ttyACM0
			stty -F $tty 115200
			exec 4<$tty 5>$tty 
			read -p "Press the reset button on the board then press ENTER" 
			timeout 10s $SCRIPT_DIR/memory_test.sh
            TEST_RESULT=$?
            echo $TEST_RESULT
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
            ;;

            "System Test")
            $SCRIPT_DIR/ping.sh &&
            $SCRIPT_DIR/t1l_power_led_test.sh
	        TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
            ;;

            "WI-FI Flash Test")
            $SCRIPT_DIR/wifi_chip_flash.sh
            $SCRIPT_DIR/check_wifi.sh
            ;;

            *) echo "Invalid option $MODE" ;;

esac
