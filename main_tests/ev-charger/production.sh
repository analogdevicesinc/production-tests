#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh


MODE="$1"
case $MODE in
     "System Test")
        sudo $SCRIPT_DIR/firmware_prod.sh
        tty=/dev/ttyACM0
        echo_blue "Serial self-test starting..."
        $SCRIPT_DIR/system_test.sh
        TEST_RESULT=$?
        if [ $TEST_RESULT -ne 0 ]; then
            handle_error_state "BOARD_SERIAL"
            exit 1;
        fi
        $SCRIPT_DIR/led_test.sh
        ;;

    *) echo "Invalid option $MODE" ;;

esac
